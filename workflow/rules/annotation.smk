rule annotate:
    input:
        asm=ASM_DIR / "{sample_id}/06_asm_reoriented.fasta",
    output:
        multiext(
            f"{RESULTS}/annotation/{{sample_id}}/{{sample_id}}",
            features=".gff3",
            ffn=".ffn",
            faa=".faa",
            plot=".png",
            json=".json",
        ),
    log:
        LOGS / "annotation/{sample_id}.log",
    threads: 4
    resources:
        mem_mb=32 * 1_024,
        runtime="30m",
    shadow:
        "shallow"
    params:
        db=BAKTA_DB,
        flags="--keep-contig-headers --gram - --complete --force",
        genus=lambda wildcards: samplesheet.loc[wildcards.sample_id, "species"][0],
        species=lambda wildcards: samplesheet.loc[wildcards.sample_id, "species"][1],
        outdir=lambda wildcards, output: Path(output[0]).parent,
    container:
        "docker://quay.io/biocontainers/bakta:1.11.3--pyhdfd78af_0"
    shell:
        """
        bakta {params.flags} --genus {params.genus} --species {params.species} -t {threads} \
          -o {params.outdir} --db {params.db} --prefix {wildcards.sample_id} {input.asm} &> {log}
        """
