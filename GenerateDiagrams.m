If[$VersionNumber < 9,
  $CMD = $CommandLine[[3 ;;]];,
  $CMD = $ScriptCommandLine;
];

Print@$CMD;

If[Length[$CMD] != 3, Print@"Incomplete args. Syntax: state loops output"; Quit[]];

$ArgLoops = ToExpression@$CMD[[2]];
$ArgOutput = $CMD[[3]];

If[$ArgLoops > 1 || $ArgLoops < 0, Print["#loops must be either zero or one"]; Quit[]];

$loopPrefix = If[$ArgLoops == 0, "tree_", ""];

(* suppress all output *)
$stdout = $Output;
$stream = OpenWrite["/dev/null"];

Get["pkg`FeynArts`FeynArts`"];
(*Get["FeynArtsToRedberry.m"];*)
$FAVerbose = 1;
$PrePrint = InputForm;


GenerateAmplitudes[] := Module[{$diagrams, $amplitudes, $eps},
  $diagrams = CreateTopologies[$ArgLoops, 1 -> 3, Adjacencies -> {3}, ExcludeTopologies -> {WFCorrections, Tadpoles}];
  $diagrams = InsertFields[$diagrams,
    {S[1]} -> {
    (*c-quark*) F[3, {2, Index[Colour, 1]}] ,
    (*c-antiquark*)-F[3, {2, Index[Colour, 2]}],
    (*gamma*) V[1]
    },
    Model -> "SMQCD",
    ExcludeParticles -> {V[1], V[2], V[3], V[4], S[_]},
    InsertionLevel -> {Particles},
    Restrictions -> {NoElectronHCoupling, NoQuarkMixing},
    ExcludeFieldPoints -> {}, LastSelections -> {}
  ];

  $amplitudes = CreateFeynAmp[$diagrams, MomentumConservation -> True];
  $amplitudes = Table[InputForm[$amplitudes[[i, 3]]], {i, 1, Length[$amplitudes]}];

  Return[$amplitudes];
];


$amplitudes = GenerateAmplitudes[];

Quiet@CreateDirectory[Directory[] <> "/" <> $ArgOutput <> "/"];

$Output = $stream;
Do[
  f = OpenWrite[Directory[] <> "/" <> $ArgOutput <> "/amp_" <> $loopPrefix <> ToString[i - 1]];
  WriteString[f, $amplitudes[[i]]];
  Close[f];
  , {i, 1, Length[$amplitudes]}
];


(* recover output *)
Close[$stream];
$Output = $stdout;
