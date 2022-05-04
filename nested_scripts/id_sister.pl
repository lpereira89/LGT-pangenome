use strict;

my($tree,@tree_cut,$i,$nameprov,$blreading,$bvreading,@group,@sisters,@sisters2,$target_name,$bootstrap,$folder,@treefiles,$j,$boot1,$boot2,$k,@temp,$johndoe);
my($line,@specieslist,$found,@counts,$filelist);

$folder=$ARGV[0]; # folder that contains the trees to scan
if(not $folder){die "forgot to specify a folder\n";}

$filelist=$ARGV[1];
if(not $filelist){die "forgot to provide a file listing the species\n";}

##############################################
# rad file containing list of taxon and groups
#############################################

undef(@specieslist);
open(IN,"<$filelist") or die "Can't file species_list file\n";
while(!eof(IN)){
    $line=readline *IN;
    $line=~ s/\r//g;
    $line=~ s/\n//g;
    @temp=split /\t/,$line;
    if(@specieslist){
        $i=0;
        $found=0;
        while($i<@specieslist){
            if($temp[1] eq $specieslist[$i][0]){
                push @{$specieslist[$i][1]},$temp[0];
                $found=1;
                }
            $i++;
            }
        if($found==0){
            $specieslist[$i][0]=$temp[1];
            push @{$specieslist[$i][1]},$temp[0];
            }
        }
    else{
        $specieslist[0][0]=$temp[1];
        push @{$specieslist[0][1]},$temp[0];
        }
    }

print "Your species list contains ".@specieslist." groups\n";
print "Their names are ".join(",",map {$_->[0]} @specieslist)."\n";

#######################################
# gets list of tree files
#######################################

`ls $folder/*phyml_tree.txt >list_trees`;

open(FILE1,"<list_trees");
$i=0;
while(!eof(FILE1)){
	$treefiles[$i]=readline *FILE1;
	$treefiles[$i]=~ s/\n//g;
	$treefiles[$i]=~ s/\r//g;
	$i++;
	}
close(FILE1);

open(OUTFILE,">results_sister");
print OUTFILE "gene\tboot1\tboot2\tsister1\tsister1_group\tsister2\tsister2_group\n";

#######################################
# starts looping through the tree files
#######################################

$j=0;
while($j<@treefiles){
@temp=split /\//,$treefiles[$j];
$target_name=$temp[-1];
$target_name=~ s/_phyml_tree.txt//g;
print "Target: ".$target_name."\n";
open(FILE1,"<$treefiles[$j]");
$tree=readline *FILE1;
$tree=~ s/\n//g;
$tree=~ s/\r//g;

##############################################
# identifies sequences composing sister groups
##############################################

undef @group;
undef @sisters;
undef @sisters2;
@tree_cut=split(//,$tree);
$i=0;
$blreading=0;
$bvreading=0;
$boot1="NA";
$boot2="NA";

$bootstrap="";
while($i<@tree_cut){
if($tree_cut[$i] eq "("){$nameprov="";$bvreading=0;}
elsif($tree_cut[$i] eq ","){
	$bvreading=0;
	if($nameprov ne ""){
		push @group,[$nameprov];
		$nameprov="";
		}
	$blreading=0;
	}
elsif($tree_cut[$i] eq ")"){
	$bvreading=1;
	if($boot1 eq "prov"){$boot1=$bootstrap;}
	if($boot2 eq "prov"){$boot2=$bootstrap;}
	if($nameprov ne ""){
		push @group,[$nameprov];
		$nameprov="";
		}
	if($boot1 eq "NA" and @group>1){
		$k=0;

		while($k<@{$group[-1]}){
			@temp=split /_/, $group[-1][$k];$johndoe=$temp[0]."_".$temp[1];
			$k++;
			}
		if($target_name~~ @{$group[-2]}){
			@sisters=@{$group[-1]};
			$boot1="prov";
			}
		$k=0;
		while($k<@{$group[-2]}){
			@temp=split /_/, $group[-2][$k];$johndoe=$temp[0]."_".$temp[1];
			$k++;
			}
		if($target_name~~ @{$group[-1]}){
			@sisters=@{$group[-2]};
			$boot1="prov";
			}
		}
	elsif($boot2 eq "NA"){
		$k=0;
		while($k<@{$group[-2]}){
			@temp=split /_/, $group[-2][$k];$johndoe=$temp[0]."_".$temp[1];
			$k++;
			}
		if($target_name~~@{$group[-1]}){
			@sisters2=@{$group[-2]};
			$boot2="prov";
			}
		$k=0;
		while($k<@{$group[-1]}){
			@temp=split /_/, $group[-1][$k];$johndoe=$temp[0]."_".$temp[1];
			$k++;
			}
		if($target_name~~@{$group[-2]}){
			@sisters2=@{$group[-1]};
			$boot2="prov";
			}
		}
	if(@group>1){
		push @{$group[-2]},@{$group[-1]};
		splice (@group,-1);
		}
	$bootstrap="";
	}
elsif($tree_cut[$i] eq ":"){
	$blreading=1;
	$bvreading=0;
	}
elsif($tree_cut[$i] eq ";"){
	$bvreading=0;
	}
elsif($bvreading==1){
	$bootstrap=$bootstrap.$tree_cut[$i];
	}
elsif($blreading==0 and $bvreading==0){$nameprov=$nameprov.$tree_cut[$i];}
$i++;
}

#####################################################################
# finished reading tree
# starts assigning sequences from the sister group to a species group
#####################################################################

print OUTFILE $target_name."\t";
if($boot1 ne "" and $boot1 ne "prov"){print OUTFILE $boot1."\t";}
else{print OUTFILE "NA\t";}
if($boot2 ne "" and $boot2 ne "prov"){print OUTFILE $boot2."\t";}
else{print OUTFILE "NA\t";}

$i=1;
undef(@counts);
print OUTFILE $sisters[0];
@temp=split /_/, $sisters[0];
$johndoe=$temp[0]."_".$temp[1];
$k=0;
$found=0;
while($k<@specieslist){
    if($johndoe~~ @{$specieslist[$k][1]}){
        $counts[$k]++;
        $found=1;
        }
    $k++;
    }
if($found==0){
        print $johndoe." not found in species list\n";
        }
while($i<@sisters){
    print OUTFILE ",".$sisters[$i];
    @temp=split /_/, $sisters[$i];
    $johndoe=$temp[0]."_".$temp[1];
    $k=0;
    $found=0;
    while($k<@specieslist){
        if($johndoe~~ @{$specieslist[$k][1]}){
            $found=1;
            $counts[$k]++;
            }
        $k++;
        }
    if($found==0){
        print $johndoe." not found in species list\n";
        }
	$i++;
	}
if($sisters[0] eq ""){print OUTFILE "\tNA";}
else{
    $k=0;
    $found=0;
    while($k<@specieslist){
        if($counts[$k]==@sisters){
            print OUTFILE "\t".$specieslist[$k][0];
            $found=1;
            }
        $k++;
        }
    }
if($found==0){print OUTFILE "\tmixed";}

$i=1;
undef(@counts);
print OUTFILE "\t";
print OUTFILE $sisters2[0];
@temp=split /_/, $sisters2[0];
$johndoe=$temp[0]."_".$temp[1];
$found=0;
$k=0;
while($k<@specieslist){
    if($johndoe~~ @{$specieslist[$k][1]}){
        $found=1;
        $counts[$k]++;
        }
    $k++;
    }
if($found==0){
    print $johndoe." not found in species list\n";
    }
while($i<@sisters2){
    print OUTFILE ",".$sisters2[$i];
    @temp=split /_/, $sisters2[$i];
    $johndoe=$temp[0]."_".$temp[1];
    $found=0;
    $k=0;
    while($k<@specieslist){
        if($johndoe~~ @{$specieslist[$k][1]}){
            $found=1;
            $counts[$k]++;
            }
        $k++;
        }
    if($found==0){
        print $johndoe." not found in species list\n";
        }
	$i++;
	}
if($sisters2[0] eq ""){print OUTFILE "\tNA";}
else{
    $k=0;
    $found=0;
    while($k<@specieslist){
        if($counts[$k]==@sisters2){
            print OUTFILE "\t".$specieslist[$k][0];
            $found=1;
            }
        $k++;
        }
    }
if($found==0){print OUTFILE "\tmixed";}
print OUTFILE "\n";
$j++;
}
