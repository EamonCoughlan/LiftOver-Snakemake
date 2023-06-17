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

#Because the good_lifted.map is not in chromosomal order, plink reorders it, jumbling all your genotypes to different SNPs.
#What a pain in the ass. This step reorders it first, making a sacrificial 'reordered.ped' so we don't mess up our ped allele order
#(from lifted2.ped) for our final output.
rule reorder_map:
    input:
        ped = 'rawdata/{sample}-lifted2.ped', #this file has correct order
        map = 'rawdata/{sample}-good_lifted.map' #this file doesn't
    output:
        temp('rawdata/{sample}-reordered.ped'), #this file doesn't, burn it.
        temp('rawdata/{sample}-reordered.map') #this file has correct order
    shell:
        'plink --ped {input.ped} --map {input.map} --recode --out rawdata/{wildcards.sample}-reordered'

rule create_final_lift:
    input:
        ped = 'rawdata/{sample}-lifted2.ped', #this file has correct order
        map = 'rawdata/{sample}-reordered.map' #this file has correct order
    output:
        'lifteddata/{sample}-GRCh38lift.ped', #this file now has correct order, I hope.
        'lifteddata/{sample}-GRCh38lift.map'
    shell:
        'plink --ped {input.ped} --map {input.map} --recode --out lifteddata/{wildcards.sample}-GRCh38lift'