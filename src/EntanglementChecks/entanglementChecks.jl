"""
kernelCheck(coordState::CoordState, kernelPolytope::Union{HPolytope{Float64,Array{Float64,1}},VPolytope{Float64,Array{Float64,1}}})

Return `true` if the Euclidean coordinates of the `coordState`` are contained in the `kernelPolytope` represented in V- or H-representation.
"""
function kernelCheck(coordState::CoordState, kernelPolytope::Union{HPolytope{Float64,Array{Float64,1}},VPolytope{Float64,Array{Float64,1}}})::Bool

    if coordState.coords ∈ kernelPolytope
        return true
    else
        return false
    end

end

"""
    pptCheck(coordState::CoordState, standardBasis::StandardBasis, precision=10)

Return `true`` if the `coordState` defined via the `standardBasis` has positive partial transposition in the given `precision`.
"""
function pptCheck(coordState::CoordState, standardBasis::StandardBasis, precision=10)::Bool

    densityState = createDensityState(coordState, standardBasis)
    ρ = densityState.densityMatrix
    d = Int(sqrt(size(ρ, 1)))

    return isPPT(ρ, d, precision)

end

"""
    realignmentCheck(coordState::CoordState, standardBasis::StandardBasis, precision=10)

Return `true`` if the realigned `coordState` defined via the `standardBasis` has trace norm ``> 1`` in the given `precision`.
"""
function realignmentCheck(coordState::CoordState, standardBasis::StandardBasis, precision=10)::Bool

    densityState = createDensityState(coordState, standardBasis)
    ρ = densityState.densityMatrix

    r_ρ = reshuffle(ρ)

    return (round(norm_trace(r_ρ), digits=precision) > 1)

end

"""
    numericEwCheck(coordState::CoordState, boundedEWs::Array{BoundedCoordEW}, relUncertainity::Float64)

Return `true` if any entanglement witness of `boundedEWs` detects the density matrix `ρ` as entangled.

An entanglement witness ``E`` of `boundedEWs` detects `ρ`, if the scalar product ``\\rho``.`coords` ``\\cdot E``.`coords` is not in [`lowerBound`, `upperBound`].
If a `relUncertainity` is given, the violation relative to `upperBound-lowerBound` needs to exceed `relUncertainity`` to detect entanglement. 
"""
function numericEwCheck(coordState::CoordState, boundedEWs::Array{BoundedCoordEW}, relUncertainity=0.0)::Bool

    anyEntanglementFound = false

    for boundedEW in boundedEWs

        intervalLength = boundedEW.upperBound - boundedEW.lowerBound
        tolerance = intervalLength * relUncertainity

        anyEntanglementFound = !(
            (boundedEW.lowerBound - tolerance)
            <= dot(coordState.coords, boundedEW.coords)
            <= (boundedEW.upperBound + tolerance)
        )

        # If one EW witnesses entanglement, we can stop
        if anyEntanglementFound == true
            break
        end

    end

    return anyEntanglementFound

end

"""
    concurrenceQpCheck(coordState::CoordState, d, dictionaries, precision=10)

Return `true` if the quasi-pure concurrence (see `concurrence.jl`) is positive for a `coordState` and given basis `dictionaries` in the given `precision`.
"""
function concurrenceQpCheck(coordState::CoordState, d, dictionaries, precision=10)::Bool

    coords = coordState.coords
    if round(getConcurrenceQP(coords, d, dictionaries), digits=precision) > 0
        return true
    else
        return false
    end

end

"""
    mubCheck(coordState::CoordState, d, stdBasis::StandardBasis, mubSet::Vector{Vector{Vector{ComplexF64}}})

Return `true` if the sum of mutual predictibilities for a `mubSet` (see `mub.jl`) of dimension `d` exceeds ``2`` for a `coordState` and given `standardBasis`.
"""
function mubCheck(coordState::CoordState, d, stdBasis::StandardBasis, mubSet::Vector{Vector{Vector{ComplexF64}}})::Bool

    ρ = createDensityState(coordState, stdBasis).densityMatrix

    if calculateCorrelation(d, mubSet, ρ) > 2
        return true
    else
        return false
    end

end

"""
    spinRepCheck(coordState::CoordState, stdBasis::StandardBasis, bipartiteWeylBasis::Vector{Array{Complex{Float64},2}}, precision=10)

Return `true` and detects a `coordState` for a `standardBasis` as separbale, if its coefficiencts in the `bipartiteWeylBasis` have 1-norm smaller than ``2`` in given `precision`.
"""
function spinRepCheck(coordState::CoordState, stdBasis::StandardBasis, bipartiteWeylBasis::Vector{Array{Complex{Float64},2}}, precision=10)

    ρ = createDensityState(coordState, stdBasis).densityMatrix
    spinRepCoefficients = map(x -> tr(ρ * x'), bipartiteWeylBasis)

    absCoeffs = map(x -> real(sqrt(x' * x)), spinRepCoefficients)

    return (round(sum(absCoeffs), digits=precision) <= 2)

end
"""
    analyseCoordState(
        d,
        coordState::CoordState,
        anaSpec::AnalysisSpecification,
        stdBasis::StandardBasis=missing,
        kernelPolytope::Union{HPolytope{Float64,Array{Float64,1}},VPolytope{Float64,Array{Float64,1}},Missing}=missing,
        bipartiteWeylBasis::Union{Vector{Array{Complex{Float64},2}},Missing}=missing,
        dictionaries::Union{Any,Missing}=missing,
        mubSet::Union{Vector{Vector{Vector{ComplexF64}}},Missing}=missing,
        boundedEWs::Union{Array{BoundedCoordEW},Missing}=missing,
        precision=10,
        relUncertainity=0.0
    )

Return an `AnalysedCoordState` for a `coordState` in `d` dimensions based on the given `anaSpec` and corresponding analysis objects.

If an entanglement check should not be carried out or if an analysis object in not passed as variable, the corresponding property in `anaSpec` needs to be `false`. 
In this case, return the corresponding property of the `AnalysedCoordState` as `missing`.
"""
function analyseCoordState(
    d,
    coordState::CoordState,
    anaSpec::AnalysisSpecification,
    stdBasis::StandardBasis=missing,
    kernelPolytope::Union{HPolytope{Float64,Array{Float64,1}},VPolytope{Float64,Array{Float64,1}},Missing}=missing,
    bipartiteWeylBasis::Union{Vector{Array{Complex{Float64},2}},Missing}=missing,
    dictionaries::Union{Any,Missing}=missing,
    mubSet::Union{Vector{Vector{Vector{ComplexF64}}},Missing}=missing,
    boundedEWs::Union{Array{BoundedCoordEW},Missing}=missing,
    precision=10,
    relUncertainity=0.0
)::AnalysedCoordState

    anaCoordState = AnalysedCoordState(
        coordState,
        missing,
        missing,
        missing,
        missing,
        missing,
        missing,
        missing
    )

    # Kernel check
    if anaSpec.kernelCheck && !ismissing(kernelPolytope)
        anaCoordState.kernel = kernelCheck(coordState, kernelPolytope)
    end

    # Spinrep check
    if anaSpec.spinrepCheck && !ismissing(stdBasis) && !ismissing(bipartiteWeylBasis)
        anaCoordState.spinrep = spinRepCheck(coordState, stdBasis, bipartiteWeylBasis, precision)
    end

    # PPT check
    if anaSpec.pptCheck && !ismissing(stdBasis)
        anaCoordState.ppt = pptCheck(coordState, stdBasis, precision)
    end

    # Realign check 
    if anaSpec.realignmentCheck && !ismissing(stdBasis)
        anaCoordState.realign = realignmentCheck(coordState, stdBasis, precision)
    end

    # Concurrence QP check 
    if anaSpec.concurrenceQpCheck && !ismissing(dictionaries)
        anaCoordState.concurrence = concurrenceQpCheck(coordState, d, dictionaries, precision)
    end

    # Mub check 
    if anaSpec.mubCheck && !ismissing(stdBasis) && !ismissing(mubSet)
        anaCoordState.mub = mubCheck(coordState, d, stdBasis, mubSet)
    end

    # numericEW check 
    if anaSpec.numericEwCheck && !ismissing(boundedEWs)
        anaCoordState.numericEW = numericEwCheck(coordState, boundedEWs, relUncertainity)
    end

    return anaCoordState

end

"""
    symAnalyseCoordState(
        d,
        coordState::CoordState,
        symmetries::Array{Permutation},
        anaSpec::AnalysisSpecification,
        stdBasis::StandardBasis=missing,
        kernelPolytope::Union{HPolytope{Float64,Array{Float64,1}},VPolytope{Float64,Array{Float64,1}},Missing}=missing,
        bipartiteWeylBasis::Union{Vector{Array{Complex{Float64},2}},Missing}=missing,
        dictionaries::Union{Any,Missing}=missing,
        mubSet::Union{Vector{Vector{Vector{ComplexF64}}},Missing}=missing,
        boundedCoordEWs::Union{Array{BoundedCoordEW},Missing}=missing,
        precision=10,
        relUncertainity=0.0
    )

Return an `AnalysedCoordState` for a `coordState` in `d` dimensions based on the given `anaSpec` and corresponding analysis objects and symmetry analysis.

If an entanglement check should not be carried out or if an analysis object in not passed as variable, the corresponding property in `anaSpec` needs to be `false`. 
In this case, return the corresponding property of the `AnalysedCoordState` as `missing`.
"""
function symAnalyseCoordState(
    d,
    coordState::CoordState,
    symmetries::Array{Permutation},
    anaSpec::AnalysisSpecification,
    stdBasis::StandardBasis=missing,
    kernelPolytope::Union{HPolytope{Float64,Array{Float64,1}},VPolytope{Float64,Array{Float64,1}},Missing}=missing,
    bipartiteWeylBasis::Union{Vector{Array{Complex{Float64},2}},Missing}=missing,
    dictionaries::Union{Any,Missing}=missing,
    mubSet::Union{Vector{Vector{Vector{ComplexF64}}},Missing}=missing,
    boundedCoordEWs::Union{Array{BoundedCoordEW},Missing}=missing,
    precision=10,
    relUncertainity=0.0
)::AnalysedCoordState

    if !anaSpec.useSymmetries
        throw("useSymmetries not specified in analysis specification")
    end

    copyAnaSpec = deepcopy(anaSpec)

    kernelCheckPassed = false
    spinrepCheckPassed = false
    pptCheckPassed = false
    realignmentCheckPassed = false
    concurrenceQpCheckPassed = false
    mubCheckPassed = false
    numericEwCheckPassed = false

    groupKernel = missing
    groupSpinrep = missing
    groupPpt = missing
    groupRealign = missing
    groupConcurrence = missing
    groupMub = missing
    groupNumericEw = missing

    # Create all symmetric states
    # Avoid duplicates 
    if length(coordState.coords) == length(unique(coordState.coords))
        symCoordStates = unique(map(
            x -> CoordState(x, coordState.eClass),
            getSymCoords(coordState.coords, symmetries)
        ))
    else
        symCoordStates = map(
            x -> CoordState(x, coordState.eClass),
            getSymCoords(coordState.coords, symmetries)
        )
    end

    # Analyse all symmetric states
    for symCoordState in symCoordStates

        analysedSymCoordState = analyseCoordState(
            d,
            symCoordState,
            copyAnaSpec,
            stdBasis,
            kernelPolytope,
            bipartiteWeylBasis,
            dictionaries,
            mubSet,
            boundedCoordEWs,
            precision,
            relUncertainity
        )

        # Update copyAnaSpecs for sym group: Skip analysis for other group states if check was successful for state
        # Kernel check implies sep in kernel which is preserved ==> Keep searching if enabled and missing
        if copyAnaSpec.kernelCheck
            kernelCheckPassed = !ismissing(analysedSymCoordState.kernel)
            if kernelCheckPassed
                groupKernel = analysedSymCoordState.kernel
            end
            copyAnaSpec.kernelCheck = !kernelCheckPassed
        end

        # Spinrep check implies SEP ==> Keep searching if enabled and (false or missing)
        if copyAnaSpec.spinrepCheck
            spinrepCheckDone = !ismissing(analysedSymCoordState.spinrep)
            spinrepCheckPassed = !ismissing(analysedSymCoordState.spinrep) && analysedSymCoordState.spinrep
            if spinrepCheckPassed
                groupSpinrep = true
            elseif spinrepCheckDone
                groupSpinrep = false
            end
            copyAnaSpec.spinrepCheck = !spinrepCheckPassed
        end

        # Ppt check determines PPT/NPT which is preserved under symmetry ==> Keep searching if enabled and missing
        if copyAnaSpec.pptCheck
            pptCheckPassed = !ismissing(analysedSymCoordState.ppt)
            if pptCheckPassed
                groupPpt = analysedSymCoordState.ppt
            end
            copyAnaSpec.pptCheck = !pptCheckPassed
        end

        # Realignment check implies entanglement which is preserved under symmetry ==> Keep searching if enabled and (false or missing)
        if copyAnaSpec.realignmentCheck
            realignmentCheckDone = !ismissing(analysedSymCoordState.realign)
            realignmentCheckPassed = !ismissing(analysedSymCoordState.realign) && analysedSymCoordState.realign
            if realignmentCheckPassed
                groupRealign = true
            elseif realignmentCheckDone
                groupRealign = false
            end
            copyAnaSpec.realignmentCheck = !realignmentCheckPassed
        end

        # Concurrence check implies entanglement which is preserved under symmetry ==> Keep searching if enabled and (false or missing)
        if copyAnaSpec.concurrenceQpCheck
            concurrenceQpCheckDone = !ismissing(analysedSymCoordState.concurrence)
            concurrenceQpCheckPassed = !ismissing(analysedSymCoordState.concurrence) && analysedSymCoordState.concurrence
            if concurrenceQpCheckPassed
                groupConcurrence = true
            elseif concurrenceQpCheckDone
                groupConcurrence = false
            end
            copyAnaSpec.concurrenceQpCheck = !concurrenceQpCheckPassed
        end

        # Mub check implies entanglement which is preserved under symmetry ==> Keep searching if enabled and (false or missing)
        if copyAnaSpec.mubCheck
            mubCheckDone = !ismissing(analysedSymCoordState.mub)
            mubCheckPassed = !ismissing(analysedSymCoordState.mub) && analysedSymCoordState.mub
            if mubCheckPassed
                groupMub = true
            elseif mubCheckDone
                groupMub = false
            end
            copyAnaSpec.mubCheck = !mubCheckPassed
        end


        # EW check implies entanglement which is preserved under symmetry ==> Keep searching if enabled and (false or missing)
        if copyAnaSpec.numericEwCheck
            numericEwCheckDone = !ismissing(analysedSymCoordState.numericEW)
            numericEwCheckPassed = !ismissing(analysedSymCoordState.numericEW) && analysedSymCoordState.numericEW
            if numericEwCheckPassed
                groupNumericEw = true
            elseif numericEwCheckDone
                groupNumericEw = false
            end
            copyAnaSpec.numericEwCheck = !numericEwCheckPassed
        end

        allDetermined = !any([
            copyAnaSpec.kernelCheck,
            copyAnaSpec.spinrepCheck,
            copyAnaSpec.pptCheck,
            copyAnaSpec.realignmentCheck,
            copyAnaSpec.concurrenceQpCheck,
            copyAnaSpec.mubCheck,
            copyAnaSpec.numericEwCheck
        ])

        if allDetermined
            break
        end

    end

    anaSymCoordState = AnalysedCoordState(
        coordState,
        groupKernel,
        groupSpinrep,
        groupPpt,
        groupRealign,
        groupConcurrence,
        groupMub,
        groupNumericEw
    )

    return anaSymCoordState

end
"""
    classifyEntanglement(analysedCoordState)

Return entanglement class of `analysedCoordState`. 

Entanglement class can be "UNKNWON", "PPT_UNKNOWN" for PPT states that can be separable or entangled, "SEP" for separable states, "BOUND" for PPT/bound entangled states or "NPT" for NPT/free entangled states.
"""
function classifyEntanglement(analysedCoordState)

    class = "UNKNOWN"

    if (!ismissing(analysedCoordState.ppt)) && !analysedCoordState.ppt #npt
        class = "NPT"
    elseif (!ismissing(analysedCoordState.kernel) && analysedCoordState.kernel) || (!ismissing(analysedCoordState.spinrep) && analysedCoordState.spinrep) #separable
        class = "SEP"
    elseif (
        !ismissing(analysedCoordState.ppt)
        && analysedCoordState.ppt
        && !(
            (!ismissing(analysedCoordState.kernel) && analysedCoordState.kernel)
            ||
            (!ismissing(analysedCoordState.spinrep) && analysedCoordState.spinrep)
        )
    ) ##ppt not sep
        class = "PPT_UNKNOWN"

        if !ismissing(analysedCoordState.realign)
            if analysedCoordState.realign
                class = "BOUND"
            end
        end
        if !ismissing(analysedCoordState.concurrence)
            if analysedCoordState.concurrence
                class = "BOUND"
            end
        end
        if !ismissing(analysedCoordState.mub)
            if analysedCoordState.mub
                class = "BOUND"
            end
        end
        if !ismissing(analysedCoordState.numericEW)
            if analysedCoordState.numericEW
                class = "BOUND"
            end
        end
    end

    return class

end


"""
    classifyAnalyzedStates!(anaCoordStates::Array{AnalysedCoordState})

Set entanglement class for array of `analysedCoordStates`.
"""
function classifyAnalyzedStates!(analysedCoordStates::Array{AnalysedCoordState})
    for anaCoordState in analysedCoordStates

        derivedClass = classifyEntanglement(anaCoordState)
        if derivedClass != "UNKNOWN"
            if anaCoordState.coordState.eClass == "UNKNOWN"
                anaCoordState.coordState.eClass = derivedClass
            else
                if anaCoordState.coordState.eClass != derivedClass
                    throw(eClassConflictException(anaCoordState))
                end
            end
        end
    end

    return analysedCoordStates
end