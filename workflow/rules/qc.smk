rule checkm2:
    input:
        asm=ASM_DIR / "{sample_id}/06_asm_reoriented.fasta",
    output:
        report=RESULTS / "QC/CheckM2/{sample_id}_checkm2.tsv",
    log:
        LOGS / "checkm2/{sample_id}.log",
    resources:
        mem_mb=18_000,
        runtime="30m",
    shadow:
        "shallow"
    threads: 4
    container:
        "docker://quay.io/biocontainers/checkm2:1.1.0--pyh7e72e81_1"
    shell:
        """
        checkm2 predict --input {input.asm} -o $TMPDIR --stdout --remove_intermediates --force -t {threads} > {output.report} 2> {log}
        """
