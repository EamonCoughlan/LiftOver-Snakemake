SAMPLES = glob_wildcards('rawdata/{condition}.ped').condition

#LiftOver - requires LiftOver executable and the mentioned files/scripts, also Python 2!
rule all:
    input:
        expand('lifteddata/{sample}-GRCh38lift.ped', sample=SAMPLES)

rule liftover:
    conda: 'py2.yaml'
    input:
        map = 'rawdata/{sample}.map',
        gz = 'hg19ToHg38.over.chain.gz'
    output:
        temp('rawdata/{sample}-lifted.map'),
        temp('rawdata/{sample}-lifted.bed.unlifted')
    shell:
        'python liftOverPlink.py --map {input.map} --out rawdata/{wildcards.sample}-lifted --chain {input.gz}'

rule remove_bad_lifts:
    input:
        'rawdata/{sample}-lifted.map'
    output:
        good = temp('rawdata/{sample}-good_lifted.map'),
        bad = temp('rawdata/{sample}-bad_lifted.dat')
    shell:
        'python rmBadLifts.py --map {input} --out {output.good} --log {output.bad}'

rule make_exclusion_list:
    input:
        bad = 'rawdata/{sample}-bad_lifted.dat',
        unlifted = 'rawdata/{sample}-lifted.bed.unlifted'
    output:
        'rawdata/{sample}-to_exclude.dat'
    shell:
        r'''
        cut -f 2 {input.bad} > {output}
        cut -f 4 {input.unlifted} | sed "/^#/d" >> {output}
        '''            

rule exclude_bad_lifts:
    input:
        'rawdata/{sample}.ped',
        'rawdata/{sample}.map',
        'rawdata/{sample}-to_exclude.dat'
    output:
        temp('rawdata/{sample}-lifted2.ped'),
        temp('rawdata/{sample}-lifted2.map')
    shell: 
        'plink --file rawdata/{wildcards.sample} --recode --out rawdata/{wildcards.sample}-lifted2 --exclude rawdata/{wildcards.sample}-to_exclude.dat'

#It appears the problem with SNP-shuffling has been fixed elsewhere and re-ordering is no longer necessary.
rule create_final_lift:
    input:
        ped = 'rawdata/{sample}-lifted2.ped', #this file has Hg19 order
        map = 'rawdata/{sample}-good_lifted.map' #this file has Hg38 order
    output:
        'lifteddata/{sample}-GRCh38lift.ped', #these files should now have correct order
        'lifteddata/{sample}-GRCh38lift.map'
    shell:
        'plink --ped {input.ped} --map {input.map} --recode --out lifteddata/{wildcards.sample}-GRCh38lift'