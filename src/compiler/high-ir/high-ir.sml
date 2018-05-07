(* high-ir.sml
 *
 * This code is part of the Diderot Project (http://diderot-language.cs.uchicago.edu)
 *
 * COPYRIGHT (c) 2015 The University of Chicago
 * All rights reserved.
 *
 * High-level version of the Diderot CFG IR
 *
 * Note: this file is generated from gen/ir/high-ir.spec and gen/ir/high-ir.in.
 *)

structure HighOps =
  struct

  (* required helper functions for types *)
    type ty = HighTypes.ty
    val samety = HighTypes.same
    val hashty = HighTypes.hash
    val tyToString = HighTypes.toString

    type mesh = meshElem.mesh
    val samemesh = meshElem.sameMesh
    val hashmesh = meshElem.hashMesh
    val meshToString = meshElem.toStringMesh

    type element = meshElem.element
    val sameelement = meshElem.sameElement
    val hashelement = meshElem.hashElement
    val elementToString = meshElem.toStringElement


  (* required helper functions for type lists *)
    type tys = ty list
    fun sametys (tys1, tys2) = ListPair.allEq samety (tys1, tys2)
    fun hashtys tys = List.foldl (fn (ty, s) => hashty ty + 0w3 * s) 0w0 tys
    fun tysToString tys = String.concat["[", String.concatWithMap "," tyToString tys, "]" ]

  (* required helper functions for the int type *)
    fun sameint (i1 : int, i2) = (i1 = i2)
    fun hashint i = Word.fromInt i
    fun intToString i = Int.toString i

  (* required helper functions for the string type *)
    fun samestring (s1 : string, s2) = (s1 = s2)
    val hashstring = HashString.hashString
    fun stringToString s = String.concat["\"", s, "\""]

  (* required helper functions for the shape type *)
    type shape = TensorShape.t
    val sameshape = TensorShape.same
    val hashshape = TensorShape.hash
    val shapeToString = TensorShape.toString

    datatype rator
      = IAdd
      | ISub
      | IMul
      | IDiv
      | IMod
      | INeg
      | LT of ty
      | LTE of ty
      | EQ of ty
      | NEQ of ty
      | GT of ty
      | GTE of ty
      | Power
      | BAnd
      | BOr
      | BNot
      | Abs of ty
      | Max of ty
      | Min of ty
      | Clamp of ty
      | MapClamp of ty
      | Lerp of ty
      | FieldPtr of int * int
      | ProbePtr of ty * ty * int * int
      | Eigen2x2
      | Eigen3x3
      | Zero of ty
      | TensorIndex of ty * shape
      | Select of ty * int
      | Subscript of ty
      | MkDynamic of ty * int
      | Append of ty
      | Prepend of ty
      | Concat of ty
      | Range
      | Length of ty
      | SphereQuery of int * ty
      | IntToReal
      | TruncToInt
      | RoundToInt
      | CeilToInt
      | FloorToInt
      | NumStrands of StrandSets.t
      | Strands of ty * StrandSets.t
      | Kernel of Kernel.t * int
      | KrnMultipleTwoD
      | KrnMultipleThreeD
      | KrnMultipleFourD
      | Inside of ImageInfo.t * int
      | ImageDim of ImageInfo.t * int
      | BorderCtlDefault of ImageInfo.t
      | BorderCtlClamp of ImageInfo.t
      | BorderCtlMirror of ImageInfo.t
      | BorderCtlWrap of ImageInfo.t
      | LoadSeq of ty * string
      | LoadImage of ty * string
      | KillAll
      | StabilizeAll
      | Print of tys
      | MathFn of MathFns.t
      | BuildMesh of mesh
      | BuildElement of element
      | BuildSpace
      | InsideFEM of int
      | InsideBASE of int
      | InsidePtr of int
      | sp_getCell
      | printIR

    fun resultArity IAdd = 1
      | resultArity ISub = 1
      | resultArity IMul = 1
      | resultArity IDiv = 1
      | resultArity IMod = 1
      | resultArity INeg = 1
      | resultArity (LT _) = 1
      | resultArity (LTE _) = 1
      | resultArity (EQ _) = 1
      | resultArity (NEQ _) = 1
      | resultArity (GT _) = 1
      | resultArity (GTE _) = 1
      | resultArity Power = 1
      | resultArity BAnd = 1
      | resultArity BOr = 1
      | resultArity BNot = 1
      | resultArity (Abs _) = 1
      | resultArity (Max _) = 1
      | resultArity (Min _) = 1
      | resultArity (Clamp _) = 1
      | resultArity (MapClamp _) = 1
      | resultArity (Lerp _) = 1
      | resultArity (FieldPtr _) = 1
      | resultArity (ProbePtr _) = 1
      | resultArity Eigen2x2 = 2
      | resultArity Eigen3x3 = 2
      | resultArity (Zero _) = 1
      | resultArity (TensorIndex _) = 1
      | resultArity (Select _) = 1
      | resultArity (Subscript _) = 1
      | resultArity (MkDynamic _) = 1
      | resultArity (Append _) = 1
      | resultArity (Prepend _) = 1
      | resultArity (Concat _) = 1
      | resultArity Range = 1
      | resultArity (Length _) = 1
      | resultArity (SphereQuery _) = 1
      | resultArity IntToReal = 1
      | resultArity TruncToInt = 1
      | resultArity RoundToInt = 1
      | resultArity CeilToInt = 1
      | resultArity FloorToInt = 1
      | resultArity (NumStrands _) = 1
      | resultArity (Strands _) = 1
      | resultArity (Kernel _) = 1
      | resultArity KrnMultipleTwoD = 1
      | resultArity KrnMultipleThreeD = 1
      | resultArity KrnMultipleFourD = 1
      | resultArity (Inside _) = 1
      | resultArity (ImageDim _) = 1
      | resultArity (BorderCtlDefault _) = 1
      | resultArity (BorderCtlClamp _) = 1
      | resultArity (BorderCtlMirror _) = 1
      | resultArity (BorderCtlWrap _) = 1
      | resultArity (LoadSeq _) = 1
      | resultArity (LoadImage _) = 1
      | resultArity KillAll = 0
      | resultArity StabilizeAll = 0
      | resultArity (Print _) = 0
      | resultArity (MathFn _) = 1
      | resultArity (BuildMesh _) = 1
      | resultArity (BuildElement _) = 1
      | resultArity BuildSpace = 1
      | resultArity (InsideFEM _) = 1
      | resultArity (InsideBASE _) = 1
      | resultArity (InsidePtr _) = 1
      | resultArity sp_getCell = 1
      | resultArity printIR = 1

    fun arity IAdd = 2
      | arity ISub = 2
      | arity IMul = 2
      | arity IDiv = 2
      | arity IMod = 2
      | arity INeg = 1
      | arity (LT _) = 2
      | arity (LTE _) = 2
      | arity (EQ _) = 2
      | arity (NEQ _) = 2
      | arity (GT _) = 2
      | arity (GTE _) = 2
      | arity Power = 2
      | arity BAnd = 2
      | arity BOr = 2
      | arity BNot = 1
      | arity (Abs _) = 1
      | arity (Max _) = 2
      | arity (Min _) = 2
      | arity (Clamp _) = 3
      | arity (MapClamp _) = 3
      | arity (Lerp _) = 3
      | arity (FieldPtr _) = 1
      | arity (ProbePtr _) = 2
      | arity Eigen2x2 = 1
      | arity Eigen3x3 = 1
      | arity (Zero _) = 0
      | arity (TensorIndex _) = 1
      | arity (Select _) = 1
      | arity (Subscript _) = 2
      | arity (MkDynamic _) = 1
      | arity (Append _) = 2
      | arity (Prepend _) = 2
      | arity (Concat _) = 2
      | arity Range = 2
      | arity (Length _) = 1
      | arity (SphereQuery _) = 2
      | arity IntToReal = 1
      | arity TruncToInt = 1
      | arity RoundToInt = 1
      | arity CeilToInt = 1
      | arity FloorToInt = 1
      | arity (NumStrands _) = 0
      | arity (Strands _) = 0
      | arity (Kernel _) = 0
      | arity KrnMultipleTwoD = 2
      | arity KrnMultipleThreeD = 3
      | arity KrnMultipleFourD = 4
      | arity (Inside _) = 2
      | arity (ImageDim _) = 1
      | arity (BorderCtlDefault _) = 2
      | arity (BorderCtlClamp _) = 1
      | arity (BorderCtlMirror _) = 1
      | arity (BorderCtlWrap _) = 1
      | arity (LoadSeq _) = 0
      | arity (LoadImage _) = 0
      | arity KillAll = 0
      | arity StabilizeAll = 0
      | arity (Print _) = ~1
      | arity (MathFn _) = ~1
      | arity (BuildMesh _) = 2
      | arity (BuildElement _) = 2
      | arity BuildSpace = 3
      | arity (InsideFEM _) = 2
      | arity (InsideBASE _) = 2
      | arity (InsidePtr _) = 2
      | arity sp_getCell = 2
      | arity printIR = 0

    fun isPure (MkDynamic _) = false
      | isPure (Append _) = false
      | isPure (Prepend _) = false
      | isPure (Concat _) = false
      | isPure KillAll = false
      | isPure StabilizeAll = false
      | isPure (Print _) = false
      | isPure _ = true

    fun same (IAdd, IAdd) = true
      | same (ISub, ISub) = true
      | same (IMul, IMul) = true
      | same (IDiv, IDiv) = true
      | same (IMod, IMod) = true
      | same (INeg, INeg) = true
      | same (LT(a0), LT(b0)) = samety(a0, b0)
      | same (LTE(a0), LTE(b0)) = samety(a0, b0)
      | same (EQ(a0), EQ(b0)) = samety(a0, b0)
      | same (NEQ(a0), NEQ(b0)) = samety(a0, b0)
      | same (GT(a0), GT(b0)) = samety(a0, b0)
      | same (GTE(a0), GTE(b0)) = samety(a0, b0)
      | same (Power, Power) = true
      | same (BAnd, BAnd) = true
      | same (BOr, BOr) = true
      | same (BNot, BNot) = true
      | same (Abs(a0), Abs(b0)) = samety(a0, b0)
      | same (Max(a0), Max(b0)) = samety(a0, b0)
      | same (Min(a0), Min(b0)) = samety(a0, b0)
      | same (Clamp(a0), Clamp(b0)) = samety(a0, b0)
      | same (MapClamp(a0), MapClamp(b0)) = samety(a0, b0)
      | same (Lerp(a0), Lerp(b0)) = samety(a0, b0)
      | same (FieldPtr(a0,a1), FieldPtr(b0,b1)) = sameint(a0, b0) andalso sameint(a1, b1)
      | same (ProbePtr(a0,a1,a2,a3), ProbePtr(b0,b1,b2,b3)) = samety(a0, b0) andalso samety(a1, b1) andalso sameint(a2, b2) andalso sameint(a3, b3)
      | same (Eigen2x2, Eigen2x2) = true
      | same (Eigen3x3, Eigen3x3) = true
      | same (Zero(a0), Zero(b0)) = samety(a0, b0)
      | same (TensorIndex(a0,a1), TensorIndex(b0,b1)) = samety(a0, b0) andalso sameshape(a1, b1)
      | same (Select(a0,a1), Select(b0,b1)) = samety(a0, b0) andalso sameint(a1, b1)
      | same (Subscript(a0), Subscript(b0)) = samety(a0, b0)
      | same (MkDynamic(a0,a1), MkDynamic(b0,b1)) = samety(a0, b0) andalso sameint(a1, b1)
      | same (Append(a0), Append(b0)) = samety(a0, b0)
      | same (Prepend(a0), Prepend(b0)) = samety(a0, b0)
      | same (Concat(a0), Concat(b0)) = samety(a0, b0)
      | same (Range, Range) = true
      | same (Length(a0), Length(b0)) = samety(a0, b0)
      | same (SphereQuery(a0,a1), SphereQuery(b0,b1)) = sameint(a0, b0) andalso samety(a1, b1)
      | same (IntToReal, IntToReal) = true
      | same (TruncToInt, TruncToInt) = true
      | same (RoundToInt, RoundToInt) = true
      | same (CeilToInt, CeilToInt) = true
      | same (FloorToInt, FloorToInt) = true
      | same (NumStrands(a0), NumStrands(b0)) = StrandSets.same(a0, b0)
      | same (Strands(a0,a1), Strands(b0,b1)) = samety(a0, b0) andalso StrandSets.same(a1, b1)
      | same (Kernel(a0,a1), Kernel(b0,b1)) = Kernel.same(a0, b0) andalso sameint(a1, b1)
      | same (KrnMultipleTwoD, KrnMultipleTwoD) = true
      | same (KrnMultipleThreeD, KrnMultipleThreeD) = true
      | same (KrnMultipleFourD, KrnMultipleFourD) = true
      | same (Inside(a0,a1), Inside(b0,b1)) = ImageInfo.same(a0, b0) andalso sameint(a1, b1)
      | same (ImageDim(a0,a1), ImageDim(b0,b1)) = ImageInfo.same(a0, b0) andalso sameint(a1, b1)
      | same (BorderCtlDefault(a0), BorderCtlDefault(b0)) = ImageInfo.same(a0, b0)
      | same (BorderCtlClamp(a0), BorderCtlClamp(b0)) = ImageInfo.same(a0, b0)
      | same (BorderCtlMirror(a0), BorderCtlMirror(b0)) = ImageInfo.same(a0, b0)
      | same (BorderCtlWrap(a0), BorderCtlWrap(b0)) = ImageInfo.same(a0, b0)
      | same (LoadSeq(a0,a1), LoadSeq(b0,b1)) = samety(a0, b0) andalso samestring(a1, b1)
      | same (LoadImage(a0,a1), LoadImage(b0,b1)) = samety(a0, b0) andalso samestring(a1, b1)
      | same (KillAll, KillAll) = true
      | same (StabilizeAll, StabilizeAll) = true
      | same (Print(a0), Print(b0)) = sametys(a0, b0)
      | same (MathFn(a0), MathFn(b0)) = MathFns.same(a0, b0)
      | same (BuildMesh(a0), BuildMesh(b0)) = samemesh(a0, b0)
      | same (BuildElement(a0), BuildElement(b0)) = sameelement(a0, b0)
      | same (BuildSpace, BuildSpace) = true
      | same (InsideFEM(a0), InsideFEM(b0)) = sameint(a0, b0)
      | same (InsideBASE(a0), InsideBASE(b0)) = sameint(a0, b0)
      | same (InsidePtr(a0), InsidePtr(b0)) = sameint(a0, b0)
      | same (sp_getCell, sp_getCell) = true
      | same (printIR, printIR) = true
      | same _ = false

    fun hash IAdd = 0w3
      | hash ISub = 0w5
      | hash IMul = 0w7
      | hash IDiv = 0w11
      | hash IMod = 0w13
      | hash INeg = 0w17
      | hash (LT(a0)) = 0w19 + hashty a0
      | hash (LTE(a0)) = 0w23 + hashty a0
      | hash (EQ(a0)) = 0w29 + hashty a0
      | hash (NEQ(a0)) = 0w31 + hashty a0
      | hash (GT(a0)) = 0w37 + hashty a0
      | hash (GTE(a0)) = 0w41 + hashty a0
      | hash Power = 0w43
      | hash BAnd = 0w47
      | hash BOr = 0w53
      | hash BNot = 0w59
      | hash (Abs(a0)) = 0w61 + hashty a0
      | hash (Max(a0)) = 0w67 + hashty a0
      | hash (Min(a0)) = 0w71 + hashty a0
      | hash (Clamp(a0)) = 0w73 + hashty a0
      | hash (MapClamp(a0)) = 0w79 + hashty a0
      | hash (Lerp(a0)) = 0w83 + hashty a0
      | hash (FieldPtr(a0,a1)) = 0w89 + hashint a0 + hashint a1
      | hash (ProbePtr(a0,a1,a2,a3)) = 0w97 + hashty a0 + hashty a1 + hashint a2 + hashint a3
      | hash Eigen2x2 = 0w101
      | hash Eigen3x3 = 0w103
      | hash (Zero(a0)) = 0w107 + hashty a0
      | hash (TensorIndex(a0,a1)) = 0w109 + hashty a0 + hashshape a1
      | hash (Select(a0,a1)) = 0w113 + hashty a0 + hashint a1
      | hash (Subscript(a0)) = 0w127 + hashty a0
      | hash (MkDynamic(a0,a1)) = 0w131 + hashty a0 + hashint a1
      | hash (Append(a0)) = 0w137 + hashty a0
      | hash (Prepend(a0)) = 0w139 + hashty a0
      | hash (Concat(a0)) = 0w149 + hashty a0
      | hash Range = 0w151
      | hash (Length(a0)) = 0w157 + hashty a0
      | hash (SphereQuery(a0,a1)) = 0w163 + hashint a0 + hashty a1
      | hash IntToReal = 0w167
      | hash TruncToInt = 0w173
      | hash RoundToInt = 0w179
      | hash CeilToInt = 0w181
      | hash FloorToInt = 0w191
      | hash (NumStrands(a0)) = 0w193 + StrandSets.hash a0
      | hash (Strands(a0,a1)) = 0w197 + hashty a0 + StrandSets.hash a1
      | hash (Kernel(a0,a1)) = 0w199 + Kernel.hash a0 + hashint a1
      | hash KrnMultipleTwoD = 0w211
      | hash KrnMultipleThreeD = 0w223
      | hash KrnMultipleFourD = 0w227
      | hash (Inside(a0,a1)) = 0w229 + ImageInfo.hash a0 + hashint a1
      | hash (ImageDim(a0,a1)) = 0w233 + ImageInfo.hash a0 + hashint a1
      | hash (BorderCtlDefault(a0)) = 0w239 + ImageInfo.hash a0
      | hash (BorderCtlClamp(a0)) = 0w241 + ImageInfo.hash a0
      | hash (BorderCtlMirror(a0)) = 0w251 + ImageInfo.hash a0
      | hash (BorderCtlWrap(a0)) = 0w257 + ImageInfo.hash a0
      | hash (LoadSeq(a0,a1)) = 0w263 + hashty a0 + hashstring a1
      | hash (LoadImage(a0,a1)) = 0w269 + hashty a0 + hashstring a1
      | hash KillAll = 0w271
      | hash StabilizeAll = 0w277
      | hash (Print(a0)) = 0w281 + hashtys a0
      | hash (MathFn(a0)) = 0w283 + MathFns.hash a0
      | hash (BuildMesh(a0)) = 0w293 + hashmesh a0
      | hash (BuildElement(a0)) = 0w307 + hashelement a0
      | hash BuildSpace = 0w311
      | hash (InsideFEM(a0)) = 0w313 + hashint a0
      | hash (InsideBASE(a0)) = 0w317 + hashint a0
      | hash (InsidePtr(a0)) = 0w331 + hashint a0
      | hash sp_getCell = 0w337
      | hash printIR = 0w347

    fun toString IAdd = "IAdd"
      | toString ISub = "ISub"
      | toString IMul = "IMul"
      | toString IDiv = "IDiv"
      | toString IMod = "IMod"
      | toString INeg = "INeg"
      | toString (LT(a0)) = concat["LT<", tyToString a0, ">"]
      | toString (LTE(a0)) = concat["LTE<", tyToString a0, ">"]
      | toString (EQ(a0)) = concat["EQ<", tyToString a0, ">"]
      | toString (NEQ(a0)) = concat["NEQ<", tyToString a0, ">"]
      | toString (GT(a0)) = concat["GT<", tyToString a0, ">"]
      | toString (GTE(a0)) = concat["GTE<", tyToString a0, ">"]
      | toString Power = "Power"
      | toString BAnd = "BAnd"
      | toString BOr = "BOr"
      | toString BNot = "BNot"
      | toString (Abs(a0)) = concat["Abs<", tyToString a0, ">"]
      | toString (Max(a0)) = concat["Max<", tyToString a0, ">"]
      | toString (Min(a0)) = concat["Min<", tyToString a0, ">"]
      | toString (Clamp(a0)) = concat["Clamp<", tyToString a0, ">"]
      | toString (MapClamp(a0)) = concat["MapClamp<", tyToString a0, ">"]
      | toString (Lerp(a0)) = concat["Lerp<", tyToString a0, ">"]
      | toString (FieldPtr(a0,a1)) = concat["FieldPtr<", intToString a0, ",", intToString a1, ">"]
      | toString (ProbePtr(a0,a1,a2,a3)) = concat["ProbePtr<", tyToString a0, ",", tyToString a1, ",", intToString a2, ",", intToString a3, ">"]
      | toString Eigen2x2 = "Eigen2x2"
      | toString Eigen3x3 = "Eigen3x3"
      | toString (Zero(a0)) = concat["Zero<", tyToString a0, ">"]
      | toString (TensorIndex(a0,a1)) = concat["TensorIndex<", tyToString a0, ",", shapeToString a1, ">"]
      | toString (Select(a0,a1)) = concat["Select<", tyToString a0, ",", intToString a1, ">"]
      | toString (Subscript(a0)) = concat["Subscript<", tyToString a0, ">"]
      | toString (MkDynamic(a0,a1)) = concat["MkDynamic<", tyToString a0, ",", intToString a1, ">"]
      | toString (Append(a0)) = concat["Append<", tyToString a0, ">"]
      | toString (Prepend(a0)) = concat["Prepend<", tyToString a0, ">"]
      | toString (Concat(a0)) = concat["Concat<", tyToString a0, ">"]
      | toString Range = "Range"
      | toString (Length(a0)) = concat["Length<", tyToString a0, ">"]
      | toString (SphereQuery(a0,a1)) = concat["SphereQuery<", intToString a0, ",", tyToString a1, ">"]
      | toString IntToReal = "IntToReal"
      | toString TruncToInt = "TruncToInt"
      | toString RoundToInt = "RoundToInt"
      | toString CeilToInt = "CeilToInt"
      | toString FloorToInt = "FloorToInt"
      | toString (NumStrands(a0)) = concat["NumStrands<", StrandSets.toString a0, ">"]
      | toString (Strands(a0,a1)) = concat["Strands<", tyToString a0, ",", StrandSets.toString a1, ">"]
      | toString (Kernel(a0,a1)) = concat["Kernel<", Kernel.toString a0, ",", intToString a1, ">"]
      | toString KrnMultipleTwoD = "KrnMultipleTwoD"
      | toString KrnMultipleThreeD = "KrnMultipleThreeD"
      | toString KrnMultipleFourD = "KrnMultipleFourD"
      | toString (Inside(a0,a1)) = concat["Inside<", ImageInfo.toString a0, ",", intToString a1, ">"]
      | toString (ImageDim(a0,a1)) = concat["ImageDim<", ImageInfo.toString a0, ",", intToString a1, ">"]
      | toString (BorderCtlDefault(a0)) = concat["BorderCtlDefault<", ImageInfo.toString a0, ">"]
      | toString (BorderCtlClamp(a0)) = concat["BorderCtlClamp<", ImageInfo.toString a0, ">"]
      | toString (BorderCtlMirror(a0)) = concat["BorderCtlMirror<", ImageInfo.toString a0, ">"]
      | toString (BorderCtlWrap(a0)) = concat["BorderCtlWrap<", ImageInfo.toString a0, ">"]
      | toString (LoadSeq(a0,a1)) = concat["LoadSeq<", tyToString a0, ",", stringToString a1, ">"]
      | toString (LoadImage(a0,a1)) = concat["LoadImage<", tyToString a0, ",", stringToString a1, ">"]
      | toString KillAll = "KillAll"
      | toString StabilizeAll = "StabilizeAll"
      | toString (Print(a0)) = concat["Print<", tysToString a0, ">"]
      | toString (MathFn(a0)) = concat["MathFn<", MathFns.toString a0, ">"]
      | toString (BuildMesh(a0)) = concat["BuildMesh<", meshToString a0, ">"]
      | toString (BuildElement(a0)) = concat["BuildElement<", elementToString a0, ">"]
      | toString BuildSpace = "BuildSpace"
      | toString (InsideFEM(a0)) = concat["InsideFEM<", intToString a0, ">"]
      | toString (InsideBASE(a0)) = concat["InsideBASE<", intToString a0, ">"]
      | toString (InsidePtr(a0)) = concat["InsidePtr<", intToString a0, ">"]
      | toString sp_getCell = "sp_getCell"
      | toString printIR = "printIR"

  end

structure HighIR = SSAFn(
  val irName = "high-ir"
  structure Ty = HighTypes
  structure Op = HighOps)

structure HighCensus = CensusFn(HighIR)
