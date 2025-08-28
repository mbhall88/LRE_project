rule abritamr:
    input:
        asm=ASM_DIR / "{sample_id}/06_asm_reoriented.fasta",
    output:
        [
            RESULTS / f"typing/AMR/{{sample_id}}/{p}"
            for p in [
                "abritamr.txt",
                "amrfinder.out",
                "summary_matches.txt",
                "summary_partials.txt",
                "summary_virulence.txt",
            ]
        ],
    log:
        LOGS / "abritamr/{sample_id}.log",
    resources:
        mem_mb=2_000,
        runtime="5m",
    shadow:
        "shallow"
    params:
        outdir=lambda wildcards, output: Path(output[0]).parent,
        species=lambda wildcards: samplesheet.loc[wildcards.sample_id, "species"]
        .replace(" ", "_")
        .lower()
        .capitalize(),
    container:
        "docker://quay.io/biocontainers/abritamr:1.0.19--pyhdfd78af_0"
    shell:
        "abritamr run -c {input.asm} --species {params.species} -p {params.outdir} &> {log}"


def species2scheme(species: str) -> str:
    """Convert species name to MLST scheme."""
    genus = species.split()[0].lower()[0]
    species = species.split()[1].lower()
    return f"{genus}{species}"


rule mlst:
    input:
        asm=ASM_DIR / "{sample_id}/06_asm_reoriented.fasta",
    output:
        tsv=RESULTS / f"typing/mlst/{{sample_id}}/mlst.tsv",
        json=RESULTS / f"typing/mlst/{{sample_id}}/mlst.json",
    log:
        LOGS / "mlst/{sample_id}.log",
    resources:
        mem_mb=2_000,
        runtime="5m",
    shadow:
        "shallow"
    params:
        scheme=lambda wildcards: species2scheme(
            samplesheet.loc[wildcards.sample_id, "species"]
        ),
    container:
        "docker://quay.io/biocontainers/mlst:2.23.0--hdfd78af_1"
    shell:
        "mlst --label {wildcards.sample_id} --scheme {params.scheme} --json {output.json} {input.asm} > {output.tsv} 2> {log}"


rule download_mob_db:
    output:
        db=directory(RESULTS / "typing/mob_suite/db"),
    log:
        LOGS / "download_mob_db.log",
    resources:
        mem_mb=8_000,
        runtime="60m",
    shadow:
        "shallow"
    container:
        "docker://quay.io/biocontainers/mob_suite:3.1.9--pyhdfd78af_1"
    shell:
        "mob_init -d {output.db} &> {log}"


rule mob_type:
    input:
        asm=ASM_DIR / "{sample_id}/06_asm_reoriented.fasta",
        db=rules.download_mob_db.output.db,
    output:
        report=RESULTS / "typing/mob_suite/{sample_id}/mobtyper_report.txt",
        results=RESULTS / "typing/mob_suite/{sample_id}/mobtyper_results.txt",
    log:
        LOGS / "mob_type/{sample_id}.log",
    threads: 4
    resources:
        mem_mb=4_000,
        runtime="30m",
    shadow:
        "shallow"
    container:
        "docker://quay.io/biocontainers/mob_suite:3.1.9--pyhdfd78af_1"
    shell:
        """
        mob_typer -d {input.db} -s {wildcards.sample_id} \
          -n {threads} --multi -g {output.report} \
          -o {output.results} -i {input.asm} &> {log}
        """

rule abricate:
    input:
        asm=ASM_DIR / "{sample_id}/06_asm_reoriented.fasta",
    output:
        RESULTS / "typing/abricate/{sample_id}.abricate.tsv",
    log:
        LOGS / "abricate/{sample_id}.log",
    resources:
        mem_mb=4_000,
        runtime="10m",
    container:
        "docker://quay.io/biocontainers/abricate:1.0.1--h05cac1d_3"
    shell:
        "abricate --db plasmidfinder {input.asm} > {output} 2> {log}"
