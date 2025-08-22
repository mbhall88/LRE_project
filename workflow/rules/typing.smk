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
        "mlst --scheme {params.scheme} --json {input.asm} {input.asm} > {output.tsv} 2> {log}"
