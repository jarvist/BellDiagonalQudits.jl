using BellDiagonalQudits
using Test
using LazySets: tovrep, vertices_list
using LinearAlgebra: Diagonal

testStandardBasis3 = create_standard_indexbasis(3, 10)
testStandardBasis4 = create_standard_indexbasis(4, 10)
testStandardKernel3 = create_kernel_polytope(3, testStandardBasis3)
testStandardKernel4 = create_kernel_polytope(4, testStandardBasis4)
testExtKernel3 = extend_vpolytope_by_densitystates(tovrep(testStandardKernel3), [create_densitystate(CoordState(1 / 9 * ones(9), "SEP"), testStandardBasis3)], 10)
testBipartiteWeylBasis3 = create_bipartite_weyloperator_basis(3)
testDictionaries3 = create_dictionary_from_basis(testStandardBasis3)
testMub3 = create_standard_mub(3)
testMub4 = create_standard_mub(4)
testRandomCoordWits = map(x -> get_bounded_coordew(x), create_random_bounded_ews(3, testStandardBasis3, 2, true, 20))
testSyms3 = generate_symmetries(testStandardBasis3, 3)
testAnaSpec = AnalysisSpecification(true, true, true, true, true, true, true, false)
testAnaSpecSym = AnalysisSpecification(true, true, true, true, true, true, true, true)

@testset "BellDiagonalQudits.jl" begin

    # BellDiagonalQudits/src/BellStates
    @test length(uniform_bell_sampler(10, 3)) == 10
    @test length(uniform_bell_sampler(10, 3, :enclosurePolytope)) == 10
    @test length(create_random_coordstates(10, 3, :magicSimplex)) == 10
    @test length(create_standard_indexbasis(4, 10).basis) == 16
    @test testDictionaries3[1][2, 1] == 6
    @test create_densitystate(CoordState(1 / 9 * ones(9), "UNKNOWN"), testStandardBasis3).coords ≈ 1 / 9 * ones(9)
    @test length(create_bipartite_weyloperator_basis(3)) == 81

    # BellDiagonalQudits/src/EntanglementWitness
    @test length(testRandomCoordWits) == 2

    # BellDiagonalQudits/src/SeparableStates
    @test length(vertices_list(tovrep(testStandardKernel3))) == 12
    @test length(vertices_list(tovrep(testStandardKernel4))) == 24
    @test length(vertices_list(testExtKernel3)) == 13

    # BellDiagonalQudits/src/Symmetries
    @test length(testSyms3) == 432
    @test get_symcoords(
        [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0],
        generate_symmetries(testStandardBasis3, 3)[1:2]
    ) == [
        [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0],
        [7.0, 8.0, 9.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0]
    ]

    # BellDiagonalQudits/src/EntanglementChecks
    @test length(testMub4) == 5
    @test all(
        map(
            i -> getfield(
                analyse_coordstate(
                    3,
                    CoordState(1 / 9 * ones(9), "UNKNOWN"),
                    testAnaSpec,
                    testStandardBasis3,
                    testStandardKernel3,
                    testBipartiteWeylBasis3,
                    testDictionaries3,
                    testMub3,
                    testRandomCoordWits
                ), i
            ) == getfield(
                AnalysedCoordState(
                    CoordState(1 / 9 * ones(9), "UNKNOWN"),
                    true,
                    true,
                    true,
                    false,
                    false,
                    false,
                    false
                ), i),
            propertynames(
                AnalysedCoordState(
                    CoordState(1 / 9 * ones(9), "UNKNOWN"),
                    true,
                    true,
                    true,
                    false,
                    false,
                    false,
                    false
                )
            )[2:8]
        )
    )
    @test all(
        map(
            i -> getfield(
                sym_analyse_coordstate(
                    3,
                    CoordState(1 / 9 * ones(9), "UNKNOWN"),
                    testSyms3[1:10],
                    testAnaSpecSym,
                    testStandardBasis3,
                    testStandardKernel3,
                    testBipartiteWeylBasis3,
                    testDictionaries3,
                    testMub3,
                    testRandomCoordWits
                ), i
            ) == getfield(
                AnalysedCoordState(
                    CoordState(1 / 9 * ones(9), "UNKNOWN"),
                    true,
                    true,
                    true,
                    false,
                    false,
                    false,
                    false
                ), i),
            propertynames(
                AnalysedCoordState(
                    CoordState(1 / 9 * ones(9), "UNKNOWN"),
                    true,
                    true,
                    true,
                    false,
                    false,
                    false,
                    false
                )
            )[2:8]
        )
    )
    @test map(
        x -> x.coordState.eClass,
        classify_analyzed_states!([
            AnalysedCoordState(
                CoordState(ones(9), "UNKNOWN"),
                true,
                true,
                true,
                false,
                false,
                false,
                false
            ),
            AnalysedCoordState(
                CoordState(ones(9), "UNKNOWN"),
                false,
                false,
                true,
                false,
                false,
                false,
                false
            ),
            AnalysedCoordState(
                CoordState(ones(9), "UNKNOWN"),
                false,
                false,
                true,
                true,
                false,
                false,
                false
            ),
            AnalysedCoordState(
                CoordState(ones(9), "UNKNOWN"),
                false,
                false,
                false,
                true,
                false,
                false,
                false
            )])
    ) == ["SEP", "PPT_UNKNOWN", "BOUND", "NPT"]
end
