(* normalize-ein.sml
 *
 * This code is part of the Diderot Project (http://diderot-language.cs.uchicago.edu)
 *
 * COPYRIGHT (c) 2015 The University of Chicago
 * All rights reserved.
 *)

structure NormalizeEin : sig

  (* normalize an Ein function; if there are no changes, then NONE is returned. *)
    val transform : Ein.ein * HighIR.var list -> Ein.ein option

  end = struct

    structure E = Ein
    structure ST = Stats


  (********** Counters for statistics **********)
    val cntNullSum              = ST.newCounter "high-opt:null-sum"
    val cntSumRewrite           = ST.newCounter "high-opt:sum-rewrite"
    val cntProbe                = ST.newCounter "high-opt:normalize-probe"
    val cntFilter               = ST.newCounter "high-opt:filter"
    val cntApplyPartial         = ST.newCounter "high-opt:apply-partial"
    val cntNegElim              = ST.newCounter "high-opt:neg-elim"
    val cntSubElim              = ST.newCounter "high-opt:sub-elim"
    val cntDivElim              = ST.newCounter "high-opt:div-elim"
    val cntDivDiv               = ST.newCounter "high-opt:div-div"
    val cntAddRewrite           = ST.newCounter "high-opt:add-rewrite"
    val cntSqrtElim             = ST.newCounter "high-opt:sqrt-elim"
    val cntEpsElim              = ST.newCounter "high-opt:eps-elim"
    val cntEpsToDeltas          = ST.newCounter "high-opt:eps-to-deltas"
    val cntNegDelta             = ST.newCounter "high-opt:neg-delta"
    val cntReduceDelta          = ST.newCounter "high-opt:reduce-delta"
    val firstCounter            = cntNullSum
    val lastCounter             = cntReduceDelta
    val cntRounds               = ST.newCounter "high-opt:normalize-round"

    fun err str = raise Fail(String.concat["Ill-formed EIN Operator", str])

    val zero = E.Const 0

    fun mkProd exps = E.Opn(E.Prod, exps)
    fun mkDiv (e1, e2) = E.Op2(E.Div, e1, e2)

  (* build a normalized summation *)
    fun mkSum ([], b) = (ST.tick cntNullSum; b)
      | mkSum (sx, b) = let
          fun return e = (ST.tick cntSumRewrite; e)
          in
            case b
             of E.Lift e => return (E.Lift(E.Sum(sx, e)))
              | E.Tensor(_, []) => return b
              | E.Zero [] => return b
              | E.Const _ => return b
              | E.ConstR _ => return b
              | E.Opn(E.Prod, es) => (case EinFilter.filterSca (sx, es)
                   of (true, e) => return e
                    | _ => E.Sum(sx, b)
                  (* end case *))
              | _ => E.Sum(sx, b)
            (* end case *)
          end

  (* build a normalized probe operation *)
    fun mkProbe (fld, x, ty) = let
          fun return e = (ST.tick cntProbe; e)
          in
            case fld
             of E.Tensor _         => err "Tensor without Lift"
              | E.Lift e           => return e
              | E.Zero _           => return fld
              | E.Partial _        => err "Probe Partial"
              | E.Probe _          => err "Probe of a Probe"
              | E.Value _          => err "Value used before expand"
              | E.Img _            => err "Probe used before expand"
              | E.Krn _            => err "Krn used before expand"
              | E.Comp _           => E.Probe(fld, x, ty) (* handled next stage*)
              | E.Epsilon _        => return fld
              | E.Eps2 _           => return fld
              | E.Const _          => return fld
              | E.Delta _          => return fld
              | E.Sum(sx1, e)      => return (E.Sum(sx1, E.Probe(e, x, ty)))
              | E.Op1(op1, e)      => return (E.Op1(op1, E.Probe(e, x, ty)))
              | E.Op2(op2, e1, e2) => return (E.Op2(op2, E.Probe(e1, x, ty), E.Probe(e2, x, ty)))
              | E.Op3(op3, e1, e2, e3) =>
                return (E.Op3(op3, E.Probe(e1, x, ty), E.Probe(e2, x, ty), E.Probe(e3, x, ty)))
              | E.Opn(opn, [])     => err "Probe of empty operator"
              | E.Opn(opn, es)     => return (E.Opn(opn, List.map (fn e => E.Probe(e, x, ty)) es))
              | E.If(E.Compare(op1, e1, e2), e3, e4)
                =>  let
                    val comp2 = E.Compare(op1, E.Probe(e1, x, ty), E.Probe(e2, x, ty))
                in (ST.tick cntProbe; (E.If(comp2, E.Probe(e3, x, ty), E.Probe(e4, x, ty)))) end
              | E.If(E.Var id, e3, e4) 
                => (ST.tick cntProbe;  E.If(E.Var id, E.Probe(e3, x, ty), E.Probe(e4, x, ty)))
              | _                  => E.Probe(fld, x, ty)
            (* end case *)
          end

    fun mkComp(F, es, x, ty) = let
        fun return e = (ST.tick cntProbe; e)
        fun setInnerProbe e = E.Probe(E.Comp(e, es), x, ty)
        val probe = setInnerProbe F
        in (case F
            of E.Tensor _        => err "Tensor without Lift"
            | E.Lift e           => return e
            | E.Zero _           => return F
            | E.Partial _        => err "Probe Partial"
            | E.Probe _          => err "Probe of a Probe"
            | E.Value _          => err "Value used before expand"
            | E.Img _            => err "Probe used before expand"
            | E.Krn _            => err "Krn used before expand"
            | E.Comp c           => probe (* handled next stage*)
            | E.Epsilon _        => return F
            | E.Eps2 _           => return F
            | E.Const _          => return F
            | E.Delta _          => return F
            | E.Sum(sx1, e)      => return (E.Sum(sx1, setInnerProbe e))
            | E.Op1(op1, e)      => return (E.Op1(op1, setInnerProbe e))
            | E.Op2(op2, e1, e2) =>
                let
                val exp1 = setInnerProbe e1
                val exp2 = setInnerProbe e2
                val xexp = E.Op2(op2, exp1, exp2)
                in return xexp end
            | E.Opn(opn, [])     => err "Probe of empty operator"
            | E.Opn(opn, es1)     =>
                let
                val exps =  List.map (fn e1 => E.Probe(E.Comp(e1, es), x, ty)) es1
                val xexp = E.Opn(opn, exps)
                in return xexp end
            | _                  => probe
            (* end case *))
        end

  (* rewrite body of EIN *)
    fun transform (ein as Ein.EIN{params, index, body}, args) = let
          (* DEBUG val _ = print(String.concat["\ntransform", EinPP.expToString(body)])*)
          fun filterProd args = (case EinFilter.mkProd args
                 of SOME e => (ST.tick cntFilter; e)
                  | NONE => mkProd args
                (* end case *))
          fun filterProdNoCnt args = (case EinFilter.mkProd args
                 of SOME e => e
                  | NONE => mkProd args
                (* end case *))

        val sumX = ref (length index)
        fun incSum() = sumX:= (!sumX+2)
        fun addSum((v, _, _)::sx) =
            sumX:= (!sumX)+v
        fun filterProd args = (case EinFilter.mkProd args
            of SOME e => (ST.tick cntFilter; e)
            | NONE => mkProd args
            (* end case *))
        fun rewrite body = (case body
                 of E.Const _ => body
                  | E.ConstR _ => body
                  | E.Tensor _ => body
                  | E.Zero _ => body
                  | E.Delta(E.C(1), E.C(1)) => (ST.tick cntReduceDelta; E.Const 1)
                  | E.Delta(E.C(0), E.C(0)) => (ST.tick cntReduceDelta; E.Const 1)
                  | E.Delta(E.C(0), E.C(1)) => (ST.tick cntReduceDelta; E.Const 0)
                  | E.Delta(E.C(1), E.C(0)) => (ST.tick cntReduceDelta; E.Const 0)
                  | E.Delta _ => body
                  | E.Epsilon _ => body
                  | E.Eps2 _ => body
                (************** Field Terms **************)
                  | E.Field _ => body
                  | E.Lift e1 => E.Lift(rewrite e1)
                  | E.Conv _ => body
                  | E.Partial _ => body
                  | E.Apply(E.Partial [], e1) => e1
                  | E.Apply(E.Partial d1, e1) => let
                      val e1 = rewrite e1
                      in
                        case Derivative.mkApply(E.Partial d1, e1, index, params,  !sumX)
                          of SOME e => (incSum();ST.tick cntApplyPartial; e)
                          | NONE => E.Apply(E.Partial d1, e1)
                        (* end case *)
                      end
                  (*sets one of the variables as a fld term *)

                  | E.Apply(E.Tensor (id, _), exp) => (case rewrite(exp)
                    of E.OField(E.CFExp tterms, fldtem, dx) => let
                        val varg = List.nth(args, id)

                        fun iter([]) = raise Fail("term isn't an input")
                        | iter ((e1, inputTy)::es) =
                            if (HighIR.Var.same(List.nth(args, e1), varg))
                            then (e1, E.F)::es (*change to field type*)
                            else (e1, inputTy)::iter(es)
                        val tterms = iter(tterms)
                        val body = E.OField(E.CFExp tterms, fldtem, dx)
                        in (ST.tick cntApplyPartial; body) end

                    | _ => body
                    (* end case*))
                  | E.Apply _ => err "Ill-formed Apply expression"
                (************** min|max **************)
                 | E.Op2(E.Min, e1, e2)     =>
                    let
                        val comp = E.Compare(E.LT, e1, e2)
                        val exp  = E.If(comp, e1, e2)
                    in (ST.tick cntProbe; exp) end
                  | E.Op2(E.Max, e1, e2)     =>
                    let
                        val comp = E.Compare(E.GT, e1, e2)
                        val exp  = E.If(comp, e1, e2)
                    in (ST.tick cntProbe; exp) end
                  | E.Op3(op3, e1, e2, e3)=> E.Op3(op3, rewrite e1, rewrite e2, rewrite e3)
                    (************** composition **************)
                 | E.OField(ofld, e, alpha)      => E.OField(ofld, rewrite e, alpha)
                 | E.Comp(E.If(comp, e3, e4), es) =>
                    let
                        (* field operation need to be pushed to leaves *)
                        val inner3 = E.Comp(e3, es)
                        val inner4 = E.Comp(e4, es)
                        val exp  = E.If(comp, inner3, inner4)
                        in(ST.tick cntProbe; exp) end
                 | E.Comp(E.Comp(a, es1), es2) => (ST.tick cntProbe; rewrite (E.Comp(a, es1@es2)))
                 | E.Comp(a, (E.Comp(b, es1), m)::es2) =>  (ST.tick cntProbe; rewrite (E.Comp(a, ((b, m)::es1)@es2)))
                 | E.Comp(e1, es)                  =>
                    let
                    val e1' = rewrite e1
                    val es' = List.map (fn (e2, n2)=> (rewrite e2, n2)) es
                    in  E.Comp(e1', es') end
                 | E.Probe(E.Comp(e1, es), x, ty)  =>
                    let
                    val e1' = rewrite e1
                    val es' = List.map (fn (e2, n2)=> (rewrite e2, n2)) es
                    in (case (rewrite(E.Comp(e1', es')))
                        of E.Comp(e1', es') => mkComp(e1', es', x, ty)
                        | e => e
                        (*end case*))
                    end
                  | E.Probe(e1, e2, ty) => mkProbe(rewrite e1, List.map rewrite e2, ty)
                (************** Field Terms **************)
                  | E.Value _ => err "Value before Expand"
                  | E.Img _ => err "Img before Expand"
                  | E.Krn _ => err "Krn before Expand"
                (************** Sum **************)
                  | E.Sum(sx, e)                  => (addSum(sx); mkSum(sx, rewrite e)) (*cshould be mksum*)
                (************* Algebraic Rewrites Op1 **************)
                  | E.Op1(E.Neg, E.Op1(E.Neg, e)) => (ST.tick cntNegElim; rewrite e)
                  | E.Op1(E.Neg, E.Const 0) => (ST.tick cntNegElim; zero)
                  | E.Op1(E.Neg, e1 as E.Zero _) => (ST.tick cntNegElim; e1)
                  | E.Op1(E.PowInt 0, e) => (ST.tick cntSqrtElim; E.Const 0)
                  | E.Op1(E.PowInt 1, e) => (ST.tick cntSqrtElim; e)
                  | E.Op1(E.Sqrt, E.Op1(E.PowInt 2, e)) => (ST.tick cntSqrtElim; E.Op1(E.Abs, e))
                  | E.Op1(op1, e1) => E.Op1(op1, rewrite e1)
                (************* Algebraic Rewrites Op2 **************)
                  | E.Op2(E.Sub, E.Const 0, e2) => (ST.tick cntSubElim; E.Op1(E.Neg, rewrite e2))
                  | E.Op2(E.Sub, e1, E.Const 0) => (ST.tick cntSubElim; rewrite e1)
                  | E.Op2(E.Sub, e1 as E.Zero _, e2) => (ST.tick cntSubElim; e1)
                  | E.Op2(E.Sub, e1, e2 as E.Zero _) => (ST.tick cntSubElim; e2)
                  | E.Op2(E.Div, E.Const 0, e2) => (ST.tick cntDivElim; zero)
                  | E.Op2(E.Div, e1 as E.Zero _, e2) => (ST.tick cntDivElim; e1)
                  | E.Op2(E.Div, E.Op2(E.Div, a, b), E.Op2(E.Div, c, d)) => (
                      ST.tick cntDivDiv;
                      rewrite (mkDiv (mkProd[a, d], mkProd[b, c])))
                  | E.Op2(E.Div, E.Op2(E.Div, a, b), c) => (
                      ST.tick cntDivDiv;
                      rewrite (mkDiv (a, mkProd[b, c])))
                  | E.Op2(E.Div, a, E.Op2(E.Div, b, c)) => (
                      ST.tick cntDivDiv;
                      rewrite (mkDiv (mkProd[a, c], b)))
                  | E.Op2(E.Div, eN, eD) => let
                        val eN = rewrite eN
                        val eD = rewrite eD
                        fun checkProd [e1] = e1
                          | checkProd es = E.Opn(E.Prod, es)

                        in (case (eN, eD)
                            of (E.Opn(E.Prod, (E.Const a)::e1), E.Opn(E.Prod, (E.Const b)::e2))
                                => if(a=b) then  (ST.tick cntDivDiv; rewrite (E.Op2(E.Div, checkProd e1, checkProd e2)))
                                    else if(a= (~1*b))
                                        then  (ST.tick cntDivDiv; rewrite (E.Op2(E.Div, checkProd ((E.Const ~1)::e1), checkProd e2)))
                                   else rewrite (E.Op2(E.Div, eN, eD))
                            | (E.Opn(E.Prod, [e1, E.Op2(E.Div, e2, e3)]), _)
                                =>
                                (ST.tick cntDivDiv; rewrite(E.Op2(E.Div, E.Opn(E.Prod, [e1, e2]),  E.Opn(E.Prod, [e3, eD]))))
                            | _ => E.Op2(E.Div, eN, eD)
                            (*end case*))
                        end
                | E.Op2(op2, e1, e2) =>  E.Op2(op2, rewrite e1, rewrite e2)
                (************* Algebraic Rewrites Opn **************)
                (* added new rewrite here*)
                | E.Opn(E.Add, [e1, e2])  =>
                    if(EinUtil.sameExp(e1, e2))
                    then (ST.tick cntAddRewrite; E.Opn(E.Prod, [E.Const 2, e1]))
                    else
                        let
                        val es' = List.map rewrite [e1, e2]
                        in
                        case EinFilter.mkAdd es'
                            of SOME body' => (ST.tick cntAddRewrite; body')
                            | NONE => E.Opn(E.Add, es')
                        end
                  | E.Opn(E.Add, es) => let
                      val es' = List.map rewrite es
                      in
                        case EinFilter.mkAdd es'
                         of SOME body' => (ST.tick cntAddRewrite; body')
                          | NONE => E.Opn(E.Add, es')
                      end


                (************* Product **************)
                  | E.Opn(E.Prod, []) => err "missing elements in product"
                  | E.Opn(E.Prod, [e1]) => rewrite e1
                  | E.Opn(E.Prod, [e1 as E.Op1(E.Sqrt, s1), e2 as E.Op1(E.Sqrt, s2)]) =>
                      if EinUtil.sameExp(s1, s2)
                        then (ST.tick cntSqrtElim; s1)
                        else filterProd [rewrite e1, rewrite e2]
                (************* Product EPS **************)
                  | E.Opn(E.Prod, (eps1 as E.Epsilon(i, j, k))::ps) => (case ps
                       of ((p1 as E.Apply(E.Partial (d as (_::_::_)), e)) :: es) => (
                            case (EpsUtil.matchEps ([i, j, k], d), es)
                             of (true, _) => (ST.tick cntEpsElim; zero)
                              | (_, []) => mkProd[eps1, rewrite p1]
                              | _ => filterProd [eps1, rewrite (mkProd (p1 :: es))]
                            (* end case *))
                        | ((p1 as E.Conv(_, _, _, (d as (_::_::_)))) :: es) => (
                            case (EpsUtil.matchEps ([i, j, k], d), es)
                             of (true, _) => (ST.tick cntEpsElim; E.Lift zero)
                              | (_, []) => mkProd[eps1, p1]
                              | _ => (case rewrite (mkProd(p1 :: es))
                                   of E.Opn(E.Prod, es') => filterProd (eps1 :: es')
                                    | e => filterProd [eps1, e]
                                  (* end case *))
                            (* end case *))
                        | [E.Tensor(_, [i1, i2])] =>
                            if (j=i1 andalso k=i2)
                              then (ST.tick cntEpsElim; zero)
                              else body
                        | _  => (case EpsUtil.epsToDels (eps1::ps)
                             of (SOME(e, sx), NONE, rest) => (case sx
                                (* Changed to Deltas*)
                                   of [] => (
                                        ST.tick cntEpsToDeltas;
                                        E.Opn(E.Prod, e::rest))
                                    | _  => (
                                        ST.tick cntEpsToDeltas;
                                        E.Opn(E.Prod, E.Sum(sx, e)::rest))
                                  (* end case *))
                              | (SOME _ , _ , _) => raise Fail "not possible"
                              | (NONE, NONE, rest) => raise Fail "not possible"
                              | (NONE, SOME(epsAll), rest) => (case rest
                                   of [] => (body) (* empty eps-product and empty rest no change *)
                                    | [r1] => (E.Opn(E.Prod, epsAll@[rewrite r1]))
                                    | _ => (case rewrite(E.Opn(E.Prod, rest))
                                         of E.Opn(E.Prod, p) => (E.Opn(E.Prod, epsAll@p))
                                          | r2 => (E.Opn(E.Prod, epsAll@[r2]))
                                        (* end case *))
                                    (* end case *))
                            (* end case *))
                      (* end case *))
                  | E.Opn(E.Prod, E.Delta d::es) => (case es
                       of [E.Op1(E.Neg, e1)] => (
                            ST.tick cntNegDelta; E.Op1(E.Neg, mkProd[E.Delta d, e1]))
                        | _ => let
                            val (pre', eps, dels, post) = EinFilter.partitionGreek(E.Delta d::es)
                            in
                              case EpsUtil.reduceDelta(eps, dels, post)
                               of (false, _) => (case (rewrite(mkProd es))
                                     of E.Opn(E.Prod, p) => mkProd (E.Delta d::p)
                                      | e2 => mkProd [E.Delta d,  e2]
                                    (* end case*))
                              (*  | (_, E.Opn(E.Prod, p)) => (ST.tick cntReduceDelta; filterProd p)*)
                                | (_, a) => (ST.tick cntReduceDelta; a)
                              (* end case *)
                            end
                      (* end case *))
                (************* Product Generic **************)
                  | E.Opn(E.Prod, [e1 as E.Zero alpha, e2]) =>
                      if (EinFilter.isScalar e2)
                        then E.Zero alpha
                        else filterProd [rewrite e1, rewrite e2]
                  | E.Opn(E.Prod, [e1, e2 as E.Zero alpha]) =>
                      if (EinFilter.isScalar e1)
                        then E.Zero alpha
                        else filterProd [rewrite e1, rewrite e2]
                (* added rewrite here*)



            | E.Opn(E.Prod, [E.Op2(E.Div, E.Const 1, e2), E.Op2(E.Div, E.Const 1 , e4), e5]) =>
                    (ST.tick cntDivElim;rewrite(E.Op2(E.Div, rewrite e5, rewrite (E.Opn(E.Prod, [rewrite e2, rewrite e4])))))

            | E.Opn(E.Prod, E.Const a::E.Const b::es)=>  (ST.tick cntDivElim; E.Opn(E.Prod, E.Const (a*b)::es))

            | E.Opn(E.Prod, [E.Op2(E.Div, e1, e2), E.Op2(E.Div, e3, e4)]) =>
                        let
                val e1' = rewrite e1
                val e2' =rewrite e2
                val e3' = rewrite e3
                val e4' =rewrite e4
                val e = E.Op2(E.Div, E.Opn(E.Prod,  [e1', e3']), E.Opn(E.Prod, [ e2', e4']))
                val e' = rewrite e
                        in
                            (ST.tick cntReduceDelta;e')
                        end




                  | E.Opn(E.Prod, [e1, e2]) => filterProd [rewrite e1, rewrite e2]
                  | E.Opn(E.Prod, e1::es) => let
                      val e' = rewrite e1
                      val e2 = rewrite (mkProd es)
                      in
                        case e2
                         of E.Opn(Prod, p') => filterProd (e' :: p')
                          | _ => filterProd [e', e2]
                        (* end case *)
                      end
                  | E.Opn(opn, es) => E.Opn(opn, List.map rewrite es)
                  | E.If(E.Compare(op1, e1, e2), e3, e4) => E.If(E.Compare(op1, rewrite e1, rewrite e2), rewrite e3, rewrite e4)
                  | E.If(E.Var id, e3, e4) => E.If(E.Var id, rewrite e3, rewrite e4)
                |  _ =>  raise Fail "unhandled"

                (* end case *))
(*DEBUG*)val start = ST.count cntRounds

        (*val _ = print (String.concat["\n\n ************ normalize ************ \n ", EX.scanBody(body)])*)

          fun loop (body, total, changed) = let
                val body' = rewrite body
                (* DEBUG
                val _ =print(String.concat["\n\n normalize ==> X:", EinPP.expToString(body), "\n\t ==> Y:", EinPP.expToString(body')])
*)



                val totalTicks = ST.sum{from = firstCounter, to = lastCounter}
                in
                  ST.tick cntRounds;
(*DEBUG*)if (ST.count cntRounds - start > 50) then raise Fail "too many steps" else ();
                  if (totalTicks > total)
                    then loop(body', totalTicks, true)
                  else if changed
                    then   SOME(Ein.EIN{params=params, index=index, body=body'})
                    else NONE
                end
          in
            loop(body, ST.sum{from = firstCounter, to = lastCounter}, false)
          end

  end
