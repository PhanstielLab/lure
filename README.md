
LURE (Command-Line)
===================

------------------------------------------------------------------------

A Probe Design Tool for Fishing Hi-C Data

### Overview

------------------------------------------------------------------------

LURE is a command line tool for designing probes targeting a particular region for Hybrid Capture Hi-C (Hi-C<sup>2</sup>).

The user supplies a genome (.fasta format), genomic coordinates, a restriction enzyme, and the desired number of probes and LURE preferentially selects the highest quality 120 base pair sequences.

#### Dependencies

-   [Bedtools](http://bedtools.readthedocs.io/en/latest/)
-   [R (version 3.3.2)](https://www.r-project.org/)
-   [HiCUP (Hi-C User Pipeline)](https://www.bioinformatics.babraham.ac.uk/projects/hicup/) and it's dependencies.
-   [GNU Parallel](https://www.gnu.org/software/parallel/)
-   UNIX-based operating system

### Quick Start

------------------------------------------------------------------------

### Details

------------------------------------------------------------------------

#### Implementation

LURE is written in BASH and R. It utilizes several command line tools (see Dependencies section) to

<!--html_preserve-->

<script type="application/json" data-for="htmlwidget-3a4e00b6475893c37960">{"x":{"diagram":"\ngraph LR\n    A-->B\n"},"evals":[],"jsHooks":[]}</script>
<!--/html_preserve-->
#### Selection Criteria

Criteria for selecting probes were modeled after Sandborn et. al. (2015) where they outline their Hi-C<sup>2</sup> method.

Briefly, potential probes were identified upstream and downstream of each restriction site. All potential probes were scored for repetitive bases, GC content, and distance from restriction site. Each probe was assigned a "Pass Number" (0-3) for overall quality according to the scheme below:

| Pass Number         | Distance from Restriction Site | Repetitive Bases | GC Content |
|---------------------|--------------------------------|------------------|------------|
| 0 (Highest Quality) | ≤ 80 bp                        | &lt; 10          | 50 - 60%   |
| 1                   | ≤ 80 bp                        | &lt; 10          | 40 - 70%   |
| 2                   | ≤ 110 bp                       | 10 - 20          | 40 - 70%   |
| 3 (Highest Quality) | ≤ 80 bp                        | &lt; 10 bases    | 50 - 60%   |

Selection critea relax as pass number increases, making the highest quality probes (passing the most restrictive criteria) pass 0 and lowest quality probes (passing the least strict criteria) pass 3.

#### Performance
