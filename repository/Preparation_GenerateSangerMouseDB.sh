#!/bin/bash

##########################################################################################
##
## Preparation_GenerateSangerMouseDB.sh
##
## Downloads known SNP and Indel data.
## Filtering out (i) low quality positions and (ii) positions from wild-type animals
##
##########################################################################################

VersionMouse=$1
temp_dir=$2
n_threads=$3
n_mem=$4

temp_dir=$(realpath $temp_dir)

wget -nv -c -r -P $temp_dir ftp://ftp-mouse.sanger.ac.uk//REL-1505-SNPs_Indels/strain_specific_vcfs/
mkdir -p $temp_dir/ftp-mouse.sanger.ac.uk/REL-1505-SNPs_Indels/wild_only/
mv -t $temp_dir/ftp-mouse.sanger.ac.uk/REL-1505-SNPs_Indels/wild_only/ $temp_dir/ftp-mouse.sanger.ac.uk/REL-1505-SNPs_Indels/strain_specific_vcfs/CAST_EiJ.mgp.v5.*
mv -t $temp_dir/ftp-mouse.sanger.ac.uk/REL-1505-SNPs_Indels/wild_only/ $temp_dir/ftp-mouse.sanger.ac.uk/REL-1505-SNPs_Indels/strain_specific_vcfs/ZALENDE_EiJ.mgp.v5.*
mv -t $temp_dir/ftp-mouse.sanger.ac.uk/REL-1505-SNPs_Indels/wild_only/ $temp_dir/ftp-mouse.sanger.ac.uk/REL-1505-SNPs_Indels/strain_specific_vcfs/MOLF_EiJ.mgp.v5.*
mv -t $temp_dir/ftp-mouse.sanger.ac.uk/REL-1505-SNPs_Indels/wild_only/ $temp_dir/ftp-mouse.sanger.ac.uk/REL-1505-SNPs_Indels/strain_specific_vcfs/SPRET_EiJ.mgp.v5.*
mv -t $temp_dir/ftp-mouse.sanger.ac.uk/REL-1505-SNPs_Indels/wild_only/ $temp_dir/ftp-mouse.sanger.ac.uk/REL-1505-SNPs_Indels/strain_specific_vcfs/PWK_PhJ.mgp.v5.*
mv -t $temp_dir/ftp-mouse.sanger.ac.uk/REL-1505-SNPs_Indels/wild_only/ $temp_dir/ftp-mouse.sanger.ac.uk/REL-1505-SNPs_Indels/strain_specific_vcfs/LEWES_EiJ.mgp.v5.*
mv -t $temp_dir/ftp-mouse.sanger.ac.uk/REL-1505-SNPs_Indels/wild_only/ $temp_dir/ftp-mouse.sanger.ac.uk/REL-1505-SNPs_Indels/strain_specific_vcfs/WSB_EiJ.mgp.v5.*

find $temp_dir/ftp-mouse.sanger.ac.uk/REL-1505-SNPs_Indels/strain_specific_vcfs/ -name  "*.mgp.v5.snps.dbSNP142.vcf.gz" | xargs -i bcftools view {} -i FILTER=\"PASS\" -o {}.filter -O z --threads $n_threads

find $temp_dir/ftp-mouse.sanger.ac.uk/REL-1505-SNPs_Indels/strain_specific_vcfs/ -name  "*.mgp.v5.indels.dbSNP142.normed.vcf.gz" | xargs -i bcftools view {} -i FILTER=\"PASS\" -o {}.filter -O z --threads $n_threads

find $temp_dir/ftp-mouse.sanger.ac.uk/REL-1505-SNPs_Indels/strain_specific_vcfs/ -name "*.filter" | xargs -i bcftools sort {} -o {}.sort -O z --max-mem $n_mem

find $temp_dir/ftp-mouse.sanger.ac.uk/REL-1505-SNPs_Indels/strain_specific_vcfs/ -name "*.filter.sort" | xargs -i tabix -p vcf {}

cwd=$(pwd)

#changing directories here, so that the input order is similar between both commands
cd $temp_dir/ftp-mouse.sanger.ac.uk/REL-1505-SNPs_Indels/strain_specific_vcfs/

bcftools merge --threads $n_threads *.snps.dbSNP142.vcf.gz.filter.sort -m none -o "$temp_dir"/Merged.mgp.v5.snps.dbSNP142.filter.vcf.gz -O z

bcftools merge --threads $n_threads  *.indels.dbSNP142.normed.vcf.gz.filter.sort -m none -o "$temp_dir"/Merged.mgp.v5.indels.dbSNP142.filter.vcf.gz -O z

cd $cwd

tabix -p vcf "$temp_dir"/Merged.mgp.v5.snps.dbSNP142.filter.vcf.gz

tabix -p vcf "$temp_dir"/Merged.mgp.v5.indels.dbSNP142.filter.vcf.gz

bcftools concat --threads $n_threads -a -O z -o $temp_dir/MGP.v5.snp_and_indels.exclude_wild.vcf.gz $temp_dir/Merged.mgp.v5.snps.dbSNP142.filter.vcf.gz $temp_dir/Merged.mgp.v5.indels.dbSNP142.filter.vcf.gz

bcftools sort -m "$n_mem"G -O z -o ref/"$VersionMouse"/MGP.v5.snp_and_indels.exclude_wild.vcf.gz $temp_dir/MGP.v5.snp_and_indels.exclude_wild.vcf.gz

tabix -p vcf ref/"$VersionMouse"/MGP.v5.snp_and_indels.exclude_wild.vcf.gz

vcf-sort -p $n_threads -c ref/"$VersionMouse"/MGP.v5.snp_and_indels.exclude_wild.vcf.gz > ref/"$VersionMouse"/MGP.v5.snp_and_indels.exclude_wild.chromosomal_sort.vcf

bgzip -@ $n_threads ref/"$VersionMouse"/MGP.v5.snp_and_indels.exclude_wild.chromosomal_sort.vcf

tabix -p vcf ref/"$VersionMouse"/MGP.v5.snp_and_indels.exclude_wild.chromosomal_sort.vcf.gz

rm -r $temp_dir/ftp-mouse.sanger.ac.uk/
rm $temp_dir/MGP.v5.snp_and_indels.exclude_wild.vcf.gz
rm $temp_dir/Merged.mgp.v5.indels.dbSNP142.filter.vcf.gz
rm $temp_dir/Merged.mgp.v5.snps.dbSNP142.filter.vcf.gz
rm $temp_dir/Merged.mgp.v5.indels.dbSNP142.filter.vcf.gz.tbi
rm $temp_dir/Merged.mgp.v5.snps.dbSNP142.filter.vcf.gz.tbi