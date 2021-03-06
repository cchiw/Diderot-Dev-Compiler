(* real-lit.sml
 *
 * This code is part of the Diderot Project (http://diderot-language.cs.uchicago.edu)
 *
 * COPYRIGHT (c) 2015 The University of Chicago
 * All rights reserved.
 *
 * Internal representation of real-valued (i.e., floating-point) literals with limited
 * support for arithmetic.
 *)

structure RealLit :> sig

    type t

  (* predicates *)
    val isZero : t -> bool              (* true for 0 or -0 *)
    val isNeg : t -> bool               (* true for negative numbers (incl. -0) *)

  (* return the representation of +/-0.0, where zero true is -0.0 *)
    val zero : bool -> t

  (* plus and minus one *)
    val one : t
    val m_one : t

  (* special math constants *)
    val pi : t

  (* special IEEE float values *)
    val nan : t                 (* some quiet NaN *)
    val posInf : t              (* positive infinity *)
    val negInf : t              (* negative infinity *)

  (* negate a real *)
    val negate : t -> t

  (* equality, comparisons, and hashing functions *)
    val same : (t * t) -> bool
    val compare : (t * t) -> order (* not ordering on reals *)
    val hash : t -> word

  (* create a real literal from pieces: isNeg is true if the number is negative, whole
   * is the whole-number part, frac is the fractional part, and exp is the
   * exponent.  This function may raise Overflow, when the exponent of the
   * normalized representation is too small or too large.
   *)
    val real : {isNeg : bool, whole : string, frac : string, exp : int} -> t

  (* create a real literal from a sign, decimal fraction, and exponent *)
    val fromDigits : {isNeg : bool, digits : int list, exp : int} -> t

  (* create a real literal from an integer *)
    val fromInt : IntInf.int -> t

  (* return a string representation of a literal.  Note that this conversion uses "-" to
   * denote negative numbers (not "~").
   *)
    val toString : t -> string

  (* external representation (for pickling) *)
    val toBytes : t -> Word8Vector.vector
    val fromBytes : Word8Vector.vector -> t

  end = struct

    structure SS = Substring
    structure W = Word
    structure W8V = Word8Vector

  (* The value {isNeg, digits=[d0, ..., dn], exp} represents the number
   *
   *    [+/-] 0.d0...dn * 10^exp
   *
   * where the sign is negative if isNeg is true.
   *)
    datatype t
      = PosInf          (* positive infinity *)
      | NegInf          (* negative infinity *)
      | NaN             (* some quiet NaN *)
      | Flt of {isNeg : bool, digits : int list, exp : int}

    fun isZero (Flt{isNeg, digits=[0], exp}) = true
      | isZero _ = false

    fun isNeg NegInf = true
      | isNeg (Flt{isNeg, ...}) = isNeg
      | isNeg _ = false

    fun zero isNeg = Flt{isNeg = isNeg, digits = [0], exp = 0}

    val one = Flt{isNeg = false, digits = [1], exp = 1}
    val m_one = Flt{isNeg = true, digits = [1], exp = 1}

  (* special math constants *)
    val pi = Flt{
            isNeg = false,
            digits=[3,1,4,1,5,9,2,6,5,3,5,8,9,7,9,3,2,3,8,4,6,2,6,4,3,3,8,3,2,8],
            exp = 1
          }

  (* special real literals *)
    val nan = NaN
    val posInf = PosInf
    val negInf = NegInf

  (* negate a real literal *)
    fun negate PosInf = NegInf
      | negate NegInf = PosInf
      | negate NaN = raise Fail "negate nan"
      | negate (Flt{isNeg, digits, exp}) =
          Flt{isNeg = not isNeg, digits = digits, exp = exp}

  (* equality, comparisons, and hashing functions *)
    fun same (NegInf, NegInf) = true
      | same (PosInf, PosInf) = true
      | same (NaN, NaN) = true
      | same (Flt f1, Flt f2) =
          (#isNeg f1 = #isNeg f2) andalso (#exp f1 = #exp f2)
          andalso (#digits f1 = #digits f2)
      | same _ = false

    fun compare (NegInf, NegInf) = EQUAL
      | compare (NegInf, _) = LESS
      | compare (_, NegInf) = GREATER
      | compare (PosInf, PosInf) = EQUAL
      | compare (PosInf, _) = LESS
      | compare (_, PosInf) = GREATER
      | compare (NaN, NaN) = EQUAL
      | compare (NaN, _) = LESS
      | compare (_, NaN) = GREATER
      | compare (Flt f1, Flt f2) = (case (#isNeg f1, #isNeg f2)
           of (false, true) => GREATER
            | (true, false) => LESS
            | _ => (case Int.compare(#exp f1, #exp f2)
                 of EQUAL => let
                      fun cmp ([], []) = EQUAL
                        | cmp ([], _) = LESS
                        | cmp (_, []) = GREATER
                        | cmp (d1::r1, d2::r2) = (case Int.compare(d1, d2)
                             of EQUAL => cmp(r1, r2)
                              | order => order
                            (* end case *))
                      in
                        cmp (#digits f1, #digits f2)
                      end
                  | order => order
                (* end case *))
          (* end case *))

    fun hash PosInf = 0w1
      | hash NegInf = 0w3
      | hash NaN = 0w5
      | hash (Flt{isNeg, digits, exp}) = let
          fun hashDigits ([], h, _) = h
            | hashDigits (d::r, h, i) =
                hashDigits (r, W.<<(W.fromInt d, i+0w4), W.andb(i+0w1, 0wxf))
          in
            hashDigits(digits, W.fromInt exp, 0w0)
          end

    fun real {isNeg, whole, frac, exp} = let
          fun cvtDigit (c, l) = (Char.ord c - Char.ord #"0") :: l
          fun isZero #"0" = true | isZero _ = false
        (* whole digits with leading zeros removed *)
          val whole = SS.dropl isZero (SS.full whole)
        (* fractional digits with trailing zeros removed *)
          val frac = SS.dropr isZero (SS.full frac)
        (* normalize by stripping leading zero digits *)
          fun normalize {isNeg, digits=[], exp} = zero isNeg
            | normalize {isNeg, digits=0::r, exp} =
                normalize {isNeg=isNeg, digits=r, exp=exp-1}
            | normalize flt = Flt flt
          in
            case SS.foldr cvtDigit (SS.foldr cvtDigit [] frac) whole
             of [] => zero isNeg
              | digits => normalize {
                    isNeg = isNeg,
                    digits = digits,
                    exp = exp + SS.size whole
                  }
            (* end case *)
          end

  (* create a real literal from a sign, decimal fraction, and exponent *)
    fun fromDigits arg = let
        (* normalize by stripping leading zero digits *)
          fun normalize {isNeg, digits=[], exp} = zero isNeg
            | normalize {isNeg, digits=0::r, exp} =
                normalize {isNeg=isNeg, digits=r, exp=exp-1}
            | normalize flt = Flt flt
          in
            normalize arg
          end

    fun fromInt 0 = zero false
      | fromInt n = let
          val (isNeg, n) = if (n < 0) then (true, ~n) else (false, n)
          fun toDigits (n, d) = if n < 10
                then IntInf.toInt n :: d
                else toDigits(IntInf.quot(n, 10), IntInf.toInt(IntInf.rem(n, 10)) :: d)
          fun cvt isNeg = let
                val digits = toDigits(n, [])
                in
                  Flt{isNeg = isNeg, digits = digits, exp = List.length digits}
                end
          in
            cvt isNeg
          end

    fun toString PosInf = "+inf"
      | toString NegInf = "-inf"
      | toString NaN = "nan"
      | toString (Flt{isNeg, digits=[0], ...}) = if isNeg then "-0.0" else "0.0"
      | toString (Flt{isNeg, digits, exp}) = let
          val s = if isNeg then "-0." else "0."
          val e = if exp < 0
                then ["e-", Int.toString(~exp)]
                else ["e", Int.toString exp]
          in
            concat(s :: List.foldr (fn (d, ds) => Int.toString d :: ds) e digits)
          end

  (***** external representation (for pickling) *****
   *
   * The representation we use is a sequence of bytes:
   *
   *    [sign, d0, ..., dn, exp0, ..., exp3]
   *
   * where
   *    sign    == 0 or 1
   *    di      == ith digit
   *    expi    == ith byte of exponent (exp0 is lsb, exp3 is msb).
   *
   * we encode Infs and NaNs using the sign byte:
   *
   *    2       == PosInf
   *    3       == NegInf
   *    4       == NaN
   *
   * NOTE: we could pack the sign and digits into 4-bit nibbles, but we are keeping
   * things simple for now.
   *)

    fun toBytes PosInf = Word8Vector.fromList [0w2]
      | toBytes NegInf = Word8Vector.fromList [0w3]
      | toBytes NaN = Word8Vector.fromList [0w4]
      | toBytes (Flt{isNeg, digits, exp}) = let
          val sign = if isNeg then 0w1 else 0w0
          val digits = List.map Word8.fromInt digits
          val exp' = W.fromInt exp
          fun byte i = Word8.fromLargeWord(W.toLargeWord((W.>>(exp', 0w8*i))))
          val exp = [byte 0w0, byte 0w1, byte 0w2, byte 0w3]
          in
            Word8Vector.fromList(sign :: (digits @ exp))
          end

    fun fromBytes v = let
          fun error () = raise Fail "Bogus real-literal pickle"
          val len = W8V.length v
          in
            if (len = 1)
              then (case W8V.sub(v, 0) (* special real value *)
                 of 0w2 => PosInf
                  | 0w3 => NegInf
                  | 0w4 => NaN
                  | _ => error()
                (* end case *))
              else let
                val ndigits = W8V.length v - 5
                val _ = if (ndigits < 1) then error() else ()
                val isNeg = (case W8V.sub(v, 0)
                       of 0w0 => false
                        | 0w1 => true
                        | _ => error()
                      (* end case *))
                fun digit i = Word8.toInt(W8V.sub(v, i+1))
                fun byte i = W.<<(
                      W.fromLargeWord(Word8.toLargeWord(W8V.sub(v, ndigits+1+i))),
                      W.fromInt(8*i))
                val exp = W.toIntX(W.orb(byte 3, W.orb(byte 2, W.orb(byte 1, byte 0))))
                in
                  Flt{isNeg = isNeg, digits = List.tabulate(ndigits, digit), exp = exp}
                end
          end

  end

