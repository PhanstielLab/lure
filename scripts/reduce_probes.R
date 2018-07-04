##  Description:
##    This script takes a list of potential probes as input, removes unpaired probes (probes
##    without forward and reverse probes), determines overlapping or gaps in probe coverage,
##    and removes probes preferentially from overlapping to lowest to highest quality from 
##    randomly chosen restriction sites


## Read in data (din, data in) and max probes ################################################################

## Read in ../output/final_probes.bed
suppressMessages(if (!require("readr")) {install.packages("readr", repos = "https://cloud.r-project.org"); library(readr)})
din <- suppressMessages(as.data.frame(read_tsv("output/final_probes.bed", col_names = F)))
colnames(din) <- c("chr", "start", "stop", "shift", "res.number", "dir", "pct_at", "pct_gc", "seq", "pass")

## Clean up unpaired probes ###################################################################################

## Number of restriction sites do not match up with forward and reverse probe numbers
#identical(length(unique(din$res.number)), length(din$start[din$dir == "r"]), length(din$stop[din$dir == "f"]))

## Here are the unique probes that do not have 2 probes (missing either forward or reverse probe)
problems <- as.numeric(names(which(table(din$res.number) != 2)))

## Lets fix this by selecting only the restrictions sites that are duplicated (meaning they will have a forward and reverse probe)
dout <- din[!(din$res.number %in% problems), ]

## They should all be the same length
if(!identical(length(unique(dout$res.number)), length(dout$start[dout$dir == "r"]), length(dout$stop[dout$dir == "f"]))){
  stop("Something is wrong...", call. = FALSE)
}

## Find overlap between each pair of probes ###################################################################

## Find indicies of forward probes (should be all odd)
fwd <- which(dout$dir == "f")

## Apply function to compute overlapping coverage and bind into data frame
intervals <- as.data.frame(cbind(res.frag=unique(dout$res.number),
                                 fstart= dout$start[dout$dir == "f"],
                                 fend= dout$stop[dout$dir == "f"],
                                 rstart= dout$start[dout$dir == "r"],
                                 rend= dout$stop[dout$dir == "r"],
                                 overlap=unlist(lapply(fwd, function(x) 
                                   length(intersect(dout$start[x]:dout$stop[x], dout$start[x+1]:dout$stop[x+1]))))
))

## Add this to dout
dout$overlap <- rep(intervals$overlap, each=2)

##  This section removes probes until max_probes == n_probes ##################################################
##
##  Removal occurs in 2 major passes: the first pass is done systematically,
##  removing the less ideal pair of overlapping probes (highest pass number) 
##  from greatest to least overlap. The second pass is done semi-randomly, 
##  randomly removing probes starting with the least ideal probes.

## Subset overlapping probes and order them descending by overlap and pass
dover <- dout[which(dout$overlap > 0),]
dover <- dover[order(-dover$overlap, -dover$pass),]

## Return indicies of unwanted overlapping probes
prune1 <- unlist(lapply(unique(dover$res.number),
function(x){ 
  temp <- dover[dover$res.number == x,] 
  return(as.numeric(row.names(temp[order(-temp$pass, -temp$shift), ][1,])))
  }
))

## Subset remaining probes, order them by pass and shift, randomly break ties
set.seed(123) # For reproducability
remaining <- dout[!(row.names(dout) %in% prune1),]
remaining <- remaining[sample(1:nrow(remaining)),]
remaining <- remaining[order(-remaining$pass, -remaining$shift),]

# Join with prune1 to create an preferential removal list
prune <- c(prune1, as.numeric(row.names(remaining)))

## Check number of probes agains max_probes
n_probes <- nrow(dout)

## Return error if argument is greater than 1
args <- commandArgs(trailingOnly = T)
if (length(args)>1) {
  stop("Supply the number of desired probes", call.=FALSE)
} else if (length(args)<1){
  max_probes = n_probes
} else if (length(args) == 1){
  max_probes = as.numeric(args[1])
}

if (max_probes > n_probes){
  dout <- dout
} else if (max_probes <= n_probes){
  section <- n_probes - max_probes
  unwanted_probes <- prune[1:section]
  dout <- dout[!(row.names(dout) %in% unwanted_probes),]
} else {
  print("Something isn't right...")
}

## Remove unnecessary overlap column
dout <- dout[,1:ncol(dout)-1]

## Write result to file
write_tsv(dout, "output/probes.bed")

## Optional Diagnostsic Plots ################################################################################
#pdf(file = sprintf("%d_probes.pdf", nrow(dout)))
# layout(matrix(c(1,1,2,3), 2, 2, byrow = TRUE))
# plot(dout$start,dout$start, xlim = c(133000000, 135000000),
#      main = sprintf("Probe Coverage (%d probes)", nrow(dout)),
#      xlab = "bp", ylab = "bp"
#      )
# plot(density(dout$pass), main = "Pass Distribution")
# hist(dout$pct_gc * 100, main = "GC Content", xlab = "% GC")
# par(mfrow=c(1,1))
#dev.off()

###############################################################################################################


