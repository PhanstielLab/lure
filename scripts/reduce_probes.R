##  Description:
##    This script takes a list of potential probes as input, removes unpaired probes (probes
##    without forward and reverse probes), determines overlapping or gaps in probe coverage,
##    and removes probes preferentially from overlapping to lowest to highest quality from 
##    randomly chosen restriction sites


## Read in data (din - data in) and max probes ################################################################

library(readr)
## Read in final_probes.bed file from an output
din <- as.data.frame(read_tsv("../output/final_probes.bed", col_names = F))
colnames(din) <- c("chr", "start", "stop", "shift", "res.number", "dir", "pct_at", "pct_gc", "seq", "pass")

max_probes <- 5000

## Clean up unpaired probes ###################################################################################
## Number of restriction sites do not match up with forward and reverse probe numbers
identical(length(unique(din$res.number)), length(din$start[din$dir == "r"]), length(din$stop[din$dir == "f"]))

## Here are the unique probes that do not have 2 probes (missing either forward or reverse probe)
problems <- as.numeric(names(which(table(din$res.number) != 2)))

## Lets fix this by selecting only the restrictions sites that are duplicated (meaning they will have a forward and reverse probe)
dout <- din[!(din$res.number %in% problems), ]

## They should all be the same length
identical(length(unique(dout$res.number)), length(dout$start[dout$dir == "r"]), length(dout$stop[dout$dir == "f"]))

## Compute intervals for overlapping probes ###################################################################

## Bind into a data frame
intervals <- as.data.frame(cbind(res.number=unique(dout$res.number), rstart= dout$start[dout$dir == "r"], fend= dout$stop[dout$dir == "f"]))
intervals$dis <- intervals$rstart - intervals$fend
intervals$diff[which(intervals$dis < 0)] <- "overlap"
intervals$diff[which(intervals$dis > 0)] <- "gap"

## Maybe this is not the best way to find overlap....
## Think of a better way than using starts and stops to compute overlap, maybe something that is coverage based.
hist(intervals$dis[intervals$dis < 0])

intervals$dis[intervals$dis < 0]

###############################################################################################################
head(dout)

