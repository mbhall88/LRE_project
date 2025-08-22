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
