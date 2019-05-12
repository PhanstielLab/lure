##  Description:
##    This script takes a list of potential probes as input, determines overlapping or gaps in probe coverage,
##    and removes probes preferentially from overlapping to lowest to highest quality from 
##    randomly chosen restriction sites


## Return error if argument is greater than 2
args <- commandArgs(trailingOnly = T)
if (length(args) == 0){
  output_folder = "/tmp/lure"
} else if (length(args) == 1 || length(args) == 2){
  output_folder = args[1]
} else {
  stop("Supply only the output folder and optionally, the number of desired probes.", call.=FALSE)
}

## Read in data (din, data in) and max probes ################################################################

## Read in /tmp/lure/all_probes.bed
suppressMessages(if (!require("readr")) {install.packages("readr", repos = "https://cloud.r-project.org"); library(readr)})
din <- suppressMessages(as.data.frame(read_tsv(paste0(output_folder, "/all_probes.bed"), col_names = F, trim_ws = F)))
colnames(din) <- c("chr", "start", "stop", "shift", "res.number", "dir", "pct_at", "pct_gc", "seq", "pass")
dout <- din

## Find Overlapping Probes and order them from worst to best quality #########################################
## Find overlap between i and i+1 probes ####
temp <- sapply(1:(nrow(din)-1), function(x) length(intersect(din$start[x]:din$stop[x], din$start[x+1]:din$stop[x+1])))
temp <- data.frame(index1=1:(nrow(din)-1), index2=1:(nrow(din)-1)+1, overlap=temp)

## Count Repetitive Regions, add shift, and pct_gc ####
temp$repetitive1 <- plyr::ldply(stringr::str_match_all(din$seq[temp$index1],"[acgt]"),length)$V1
temp$repetitive2 <- plyr::ldply(stringr::str_match_all(din$seq[temp$index2],"[acgt]"),length)$V1
temp$shift1 <- din$shift[temp$index1]
temp$shift2 <- din$shift[temp$index2]
temp$pct_gc1 <- din$pct_gc[temp$index1]
temp$pct_gc2 <- din$pct_gc[temp$index2]

## Keep only overlapping probes and order by reverse quality ####
temp <- temp[temp$overlap > 0,]
temp <- temp[order(temp$overlap,
                   temp$repetitive1, temp$repetitive2,
                   temp$shift1, temp$shift2,
                   temp$pct_gc1, temp$pct_gc2, decreasing = T),]

## Choose the worst of the two overlapping probes to remove ####
set.seed(123)
prune1 <- sapply(1:nrow(temp), function(i){
  if(temp$repetitive1[i] == temp$repetitive2[i]){
    if(temp$shift1[i] == temp$shift2[i]){
      if(temp$pct_gc1[i] == temp$pct_gc2[i]){
        return(sample(c(temp$index1[i], temp$index2[i]), 1))
      }else{
        if(abs(temp$pct_gc1[i]-0.5) >= abs(temp$shift2[i]-0.5)) return(temp$index2[i]) else return(temp$index1[i])
      }
    }else{
      if(temp$shift1[i] > temp$shift2[i]) return(temp$index2[i]) else return(temp$index1[i])
    }
  }else{
    if(temp$repetitive1[i] > temp$repetitive2[i]) return(temp$index2[i]) else return(temp$index1[i])
  }
})

## Remove overlapping probes from list and generate removal order from worst to best probes ####
temp2 <- din[-prune1,]
temp2$repetitive <- plyr::ldply(stringr::str_match_all(temp2$seq,"[acgt]"),length)$V1
temp2$gc_score <- abs(temp2$pct_gc - 0.5)
set.seed(123)
temp2 <- temp2[order(temp2$repetitive, temp2$shift, temp2$gc_score, runif(nrow(temp2)), decreasing = T),]

## Join with prune1 to create an preferential removal list ####
prune <- unique(c(prune1, as.numeric(rownames(temp2))))

## Check number of probes agains max_probes
n_probes <- nrow(dout)
if (length(args) == 2){
  max_probes = suppressWarnings(as.numeric(args[2]))
} else {
  max_probes = n_probes
}

if (max_probes >= n_probes | is.na(max_probes)){
  dout <- dout
} else if (max_probes < n_probes){
  section <- n_probes - max_probes
  unwanted_probes <- prune[1:section]
  dout <- dout[!(row.names(dout) %in% unwanted_probes),]
} else {
  print("Something isn't right...")
}

## Write result to file
write_tsv(dout, paste0(output_folder, "/filtered_probes.bed"), col_names = F)

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


