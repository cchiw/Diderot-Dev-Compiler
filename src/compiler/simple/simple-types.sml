(* simple-types.sml
 *
 * This code is part of the Diderot Project (http://diderot-language.cs.uchicago.edu)
 *
 * COPYRIGHT (c) 2015 The University of Chicago
 * All rights reserved.
 *
 * Internal representation of Diderot types after simplification.  This is essentially
 * the Types representation with the meta variables stripped out.
 *)

structure SimpleTypes =
  struct

    datatype ty
      = T_Bool
      | T_Int
      | T_String
    (* scalars, vectors, matrices, etc.; argument is tensor shape *)
      | T_Tensor of shape
      | T_Sequence of ty * int option   (* sequence of values; second argument is length *)
      | T_Tuple of ty list              (* tuple of values *)
      | T_Strand of Atom.atom           (* strand type *)
    (* convolution kernel *)
      | T_Kernel
    (* data sets from NRRD *)
      | T_Image of ImageInfo.t          (* image properties; either from proxy image or
                                         * synthetic.
                                         *)
    (* continuous field reconstructed from a data set *)
      | T_Field of {
          diff : diff,                  (* number of levels of differentiation supported *)
          dim : dim,                    (* dimension of domain (2D or 3D field) *)
          shape : shape                 (* shape of tensors in range; order is length of list *)
        }
      | T_OField of {
        diff : diff,                  (* number of levels of differentiation supported *)                    (* dimension of domain (2D or 3D field) *)
        shape : shape,                 (* shape of tensors in range; order is length of list *)
        input : shape list
        }
      | T_FemFld of {
        diff : diff,                  (* number of levels of differentiation supported *)
        dim : dim,                    (* dimension of domain (2D or 3D field) *)
        shape : shape                 (* shape of tensors in range; order is length of list *)
        }
      | T_Mesh
      | T_Element
      | T_FnSpace

    withtype diff = int option
         and shape = int list
         and dim = int

  (* instantiated meta variable values *)
    datatype meta_arg
      = TY of ty
      | DIFF of diff
      | SHAPE of shape
      | DIM of dim

    val realTy = T_Tensor[]

    fun tupleTy [ty] = ty
      | tupleTy tys = T_Tuple tys

  (* compare types for equality *)
    fun same (ty1, ty2) = (case (ty1, ty2)
	   of (T_Bool, T_Bool) => true
	    | (T_Int, T_Int) => true
	    | (T_String, T_String) => true
	    | (T_Tensor shp1, T_Tensor shp2) => ListPair.allEq (op =) (shp1, shp2)
	    | (T_Sequence(ty1, NONE), T_Sequence(ty2, NONE)) => same (ty1, ty2)
	    | (T_Sequence(ty1, SOME n1), T_Sequence(ty2, SOME n2)) =>
		(n1 = n2) andalso same (ty1, ty2)
	    | (T_Tuple tys1, T_Tuple tys2) => ListPair.allEq same (tys1, tys2)
	    | (T_Strand s1, T_Strand s2) => Atom.same(s1, s2)
	    | (T_Kernel, T_Kernel) => true
	    | (T_Image info1, T_Image info2) => ImageInfo.same(info1, info2)
	    | (T_Field{diff=k1, dim=d1, shape=shp1}, T_Field{diff=k2, dim=d2, shape=shp2}) =>
			(k1 = k2) andalso (d1 = d2) andalso ListPair.allEq (op =) (shp1, shp2)
        | (T_OField{diff=k1,  shape=shp1, input=i1}, T_OField{diff=k2,  shape=shp2, input=i2}) =>
                (k1 = k2)  andalso ListPair.allEq (op =) (shp1, shp2) 
                andalso ListPair.allEq (op =) (i1, i2)
        | (T_FemFld{diff=k1, dim=d1, shape=shp1}, T_FemFld{diff=k2, dim=d2, shape=shp2}) =>
                (k1 = k2) andalso (d1 = d2) andalso ListPair.allEq (op =) (shp1, shp2)
        | (T_Mesh, T_Mesh) => true
        | (T_Element, T_Element) => true
        | (T_FnSpace, T_FnSpace) => true
	    | _ => false
	  (* end case *))

    local
      val shapeToString = String.concatWithMap "," Int.toString
    in
    fun toString ty = (case ty
           of T_Bool => "bool"
            | T_Int => "int"
            | T_String => "string"
            | T_Tensor[] => "real"
            | T_Tensor[2] => "vec2"
            | T_Tensor[3] => "vec3"
            | T_Tensor[4] => "vec4"
            | T_Tensor shape => concat["tensor[", shapeToString shape, "]"]
            | T_Sequence(ty, NONE) => toString ty ^ "[]"
            | T_Sequence(ty, SOME dim) => concat[toString ty, "[", Int.toString dim, "]"]
            | T_Tuple tys => concat["(", String.concatWithMap "," toString tys, ")"]
            | T_Strand id => Atom.toString id
            | T_Kernel => "kernel"
            | T_Image info => ImageInfo.toString info
            | T_Field{diff=NONE, dim, shape} => concat[
                   "field", "(", Int.toString dim, ")[", shapeToString shape, "]"
                 ]
            | T_Field{diff=SOME k, dim, shape} => concat[
                   "field#", Int.toString k, "(", Int.toString dim,
                   ")[", shapeToString shape, "]"
                ]
            | T_OField{diff=NONE, shape, input} => concat[
                   "ofield(", String.concatWithMap "," shapeToString input, ")[", shapeToString shape, "]"
                 ]
            | T_OField{diff=SOME k, shape, input} => concat[
                   "ofield#", Int.toString k,"(",String.concatWithMap "," shapeToString input,")",
                   "[", shapeToString shape, "]"
                   ]
            | T_FemFld{diff=NONE, dim, shape} => concat[
                   "femfield", "(", Int.toString dim, ")[", shapeToString shape, "]"
                 ]
            | T_FemFld{diff=SOME k, dim, shape} => concat[
                   "femfield#", Int.toString k, "(", Int.toString dim,")[", shapeToString shape, "]"
                ]
            | T_Mesh => "meshTy"
            | T_Element => "ElementTy"
            | T_FnSpace => "FnSpace"
          (* end case *))
    end (* local *)

  end
