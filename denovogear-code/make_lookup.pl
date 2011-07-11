#!/usr/bin/perl
use warnings;


$MIN_LIKE=1e-26;
$MRATE=1e-8;
$POLY_RATE=1e-3;

my @gts=("AA","AC","AG","AT","CC","CG","CT","GG","GT","TT");
my @seqs=("A","A","A","A","C","C","C","G","G","T");
my @seq2=("A","C","G","T","C","G","T","G","T","T");

my $cid=0,$mid=0,$did=0;
 @inf=(); #trio coding 
 @tprob=(); #transmission prob
 @snp_status=(); #number of alleles in trio

  $k=0;

#mp = 1 if parent who is missing/homozygous is dad; 2=mom;3=both
# hz =1 means non-missing parent is homozygous

open(OUT,">lookup.txt");

for ($did=0;$did<10;$did++){

    for ($cid=0;$cid<10;$cid++){

	for ($mid=0;$mid<10;$mid++){


	    $denovo=0;

            
	    $gt_string=join ("/",$seqs[$cid].$seq2[$cid],$seqs[$mid].$seq2[$mid],$seqs[$did].$seq2[$did]);

	    my $prev = 'nonesuch';
         
	    @alleles=($seqs[$cid],$seq2[$cid],$seqs[$mid],$seq2[$mid],$seqs[$did],$seq2[$did]);
            @sa = sort {$a cmp $b} @alleles;
                     
	    @uniqalleles = grep($_ ne $prev && (($prev) = $_),@sa);
                  
	    $snp_status[$k]=$#uniqalleles+1;

	    $ret=get_priors(\@alleles,$#uniqalleles);
            @priors=@{$ret}; 

	#    print "uniq $#uniqalleles $alleles[0]\n";

#4 or more alleles, abort
	    if ($#uniqalleles>=3){

		$tprob[$k]=0;
                $inf[$k]=9; 
		print_info();

                $k++;
		next;

	    }

#triallelic, simplified analysis
	    if ($#uniqalleles==2){
           
		$inf[$k]=9;

            #check that child alleles in parents    
		if (grep(/$seqs[$cid]/,($seqs[$did],$seq2[$did]))!=0 && grep(/$seq2[$cid]/,($seqs[$mid],$seq2[$mid]))!=0	     	){ 
#print "mendelian triallelic $gts[$cid] $gts[$mid] $gts[$did]\n";

if ($seqs[$cid] eq $seq2[$cid]){$tprob[$k]=.25}
elsif ($seqs[$mid] eq $seq2[$mid] || $seqs[$did] eq $seq2[$did]){ $tprob[$k]=.5;}
else{ $tprob[$k]=.25;}

}
		else{$tprob[$k]=0;}


		print_info();
		$k++;
		next;
	    }
# 1. Child is missing data or homozygous
         if ($seqs[$cid] eq $seq2[$cid]){
        
# 1b.mom and dad homozygous for same allele; class D
     if ($seqs[$did] eq $seq2[$did] && $seqs[$mid] eq $seq2[$mid]){$inf[$k]=6; $tprob[$k]=1;}
     
     # 1c. mom homozygous or missing data, dad heterozygous; class E
     elsif ($seqs[$did] ne $seq2[$did] && $seqs[$mid] eq $seq2[$mid]){$inf[$k]=7; $tprob[$k]=.5;}
 
     # 1d. dad homozygous or missing data, mom heterozygous; class F
     elsif ($seqs[$mid] ne $seq2[$mid] && $seqs[$did] eq $seq2[$did]){$inf[$k]=8; $tprob[$k]=.5;}
  
     #  both parents het   G
         elsif ($seqs[$mid] ne $seq2[$mid] && $seqs[$did] ne $seq2[$did]){$inf[$k]=9; $tprob[$k]=.25;}
 }
     
     
#2. Child is Het 
    else {


$inf[$k]=9;

    # 2a.mom and dad homozygous for same allele;
     if ($seqs[$mid] eq $seq2[$mid] && $seqs[$did] eq $seq2[$did]){$tprob[$k]=1;}

     # 2b. mom homozygous or missing data, dad heterozygous; 
     elsif ($seqs[$did] ne $seq2[$did] && $seqs[$mid] eq $seq2[$mid]){$tprob[$k]=.5;}
 
     # 2c. dad homozygous or missing data, mom heterozygous;
     elsif ($seqs[$mid] ne $seq2[$mid] && $seqs[$did] eq $seq2[$did]){$tprob[$k]=.5;}

     # 2d. dad het, mom heterozygous;
     elsif ($seqs[$mid] ne $seq2[$mid] && $seqs[$did] ne $seq2[$did]){$tprob[$k]=.25;}

}
   
  if ($inf[$k] == 0){die "problems with assigning trio config in main $seqs[$cid] $seq2[$cid] $seqs[$mid] $seq2[$mid] $seqs[$did] $seq2[$did]\n";
                               }


  
#Check for MIs
        
         $p1=0;$p2=0;$p12=0;$p22=0;

     if (($seqs[$cid] eq $seq2[$mid]) || ($seqs[$cid] eq $seqs[$mid])) {$p1++;}
     if (($seqs[$cid] eq $seq2[$did]) || ($seqs[$cid] eq $seqs[$did])) {$p2++;}
     if (($p1==0) && ($p2==0)) {$test2=1;} else {$test2=0;}    
     
       if ($seq2[$cid] eq $seqs[$mid]){$p12++;}
       if ($seq2[$cid] eq $seq2[$mid]){$p12++;}
       if ($seq2[$cid] eq $seqs[$did]){$p22++;}
       if ($seq2[$cid] eq $seq2[$did]){$p22++;}
       if(($p12==0) && ($p22==0)){$test3=1;} else {$test3=0;}
       $p1=$p1+$p12;
       $p2=$p2+$p22;      
       if(($test2==0)||($test3==0)){
         if ($p1==0){$z++;$d=1;$dc=2;$inf[$k]=1;} #dc=2 indicates mom is deletion carrier
         elsif ($p2==0){$z++;$d=1;$dc=1;$inf[$k]=2;}
         
     }
         if ($test2==1 || $test3==1) {$inf[$k]=3;}


if ($inf[$k]<6){$tprob[$k]=0;}
if ($inf[$k]==3){

    

		 $inf[$k]=ts_tv_call(\@alleles); #call transition or transversion

}       
	    print_info();
	  #  if ($inf[$k]>3){ print "mendelian  normal $gts[$cid] $gts[$mid] $gts[$did]\n" ;}
	    $k++;
	}
    }

}

close(OUT);

#open(OUT,">table.txt");

#for ($j=0;$j<$k;$j++){

#print OUT " 


sub ts_tv_call{

    my @alleles=@{$_[0]};
    my $out=3;

   # foreach $el (@alleles){print "$el ";}print "\n";
  #  $test  = grep /A/,@alleles;
 #   $test2 = grep /G/,@alleles;
#    print "ts tv $test $test2\n";

    if ($alleles[0] eq $alleles[1]){$out=3;$denovo=$MRATE*$MRATE;} #homozygous child
    elsif (grep(/C/,@alleles)!=0 && grep(/T/,@alleles)!=0){$out=4;$denovo=$MRATE;} #transition
    elsif (grep(/A/,@alleles)!=0 && grep(/G/,@alleles)!=0){$out=4;$denovo=$MRATE;} #transition
    else {$out=5;$denovo=$MRATE;} #transversion
    return $out;

}

sub print_info{

	    print OUT "$snp_status[$k] $inf[$k] $tprob[$k] $gt_string $denovo ";

#combine priors and transmission likelihoods

	    foreach $el (@priors){ $o=$el*$tprob[$k]; print OUT "$o ";} print OUT "\n";
      
#    print OUT " $#uniqalleles $seqs[$cid] $seq2[$cid] $seqs[$mid] $seq2[$mid] $seqs[$did] $seq2[$did] $inf[$k] $tprob[$k]\n";

	}



sub get_priors{
#expect that only two alleles are present in the array

my    @all=@{$_[0]}[2..5] ;#just retain parents mom,dad
my    $nuniq=$_[1]; 
my    @uniq;

my	@ref=("A","C","G","T");
my @priors;
my $i=0;
my $prev='nonesuch';
            my @sa = sort {$a cmp $b} @all;
                     
	    @uniq = grep($_ ne $prev && (($prev) = $_),@sa);



for ($i=0;$i<4;$i++){

    if ($nuniq > 2 ) {$priors[$i]=$MIN_LIKE; next;}
    if ($nuniq == 2 ){ $priors[$i]=$POLY_RATE * $POLY_RATE ; next;}

    $nhit=grep /$ref[$i]/,@all;

    
#ref not in the genotypes
    if ($nhit == 0){

    if ($#uniq==0){$priors[$i]=.002*(3.0/5.0)*(1.0/5.0);} #0 copies of ref in parents

    else {$priors[$i]=$POLY_RATE*$POLY_RATE;} #triallelic  
}
#ref in the genotypes
    elsif ($nhit >0){

	if ($nhit==4){$priors[$i]=.998;} #4 copies of the ref

        elsif ($nhit==3){$priors[$i]=.002*(3.0/5.0)*(4.0/5.0)*.5  ;} #3 copy of ref in parents
        
        elsif ($nhit==2){ #two 

	    if ($all[0] eq $all[1] && $all[2] eq $all[3]){$priors[$i]=.002*(2.0/5.0)*(1.0/5.0)*.5;} 

	    elsif ($all[0] ne $all[1] && $all[2] ne $all[3]){$priors[$i]=.002*(2.0/5.0)*(2.0/5.0);} 
            
            else {print "\n $ref[$i] all $all[0] $all[1] $all[2] $all[3]\n"; die "Exception 1 in priors\n";}
	}

        elsif ($nhit==1){ #one 
	
         $priors[$i]=.002*(2.0/5.0)*(2.0/5.0) *.5;} 

    
	else {die "Exception 2 in priors\n";}
    }
    else {die "exception 3 in priors\n";}

}
#            foreach $el (@priors){ print "$el "; } print  "\n";
return \@priors;
}


	       
