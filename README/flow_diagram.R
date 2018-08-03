library(DiagrammeR)
mermaid("
        graph TB
        A(User Input)-->B(Digest ROI to get Restriction Fragments)
        B-->C(Construct & Score Probes)
        C-->D(Create Forward Probes)
        C-->E(Create Reverse Probes)
        D-->Q(Select Forward Probes)
        E-->R(Select Reverse Probes)
        Q-->F(Pass 0)
        Q-->G(Pass 1)
        Q-->H(Pass 2)
        Q-->I(Pass 3)
        R-->J(Pass 0)
        R-->K(Pass 1)
        R-->L(Pass 2)
        R-->M(Pass 3)
        F-->N(Combine & Remove Duplicates)
        G-->N
        H-->N
        I-->N
        J-->N
        K-->N
        L-->N
        M-->N
        N-->O(Prune to Desired Probe Number)
        O-->P(Output)
        ")