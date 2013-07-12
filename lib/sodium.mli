(** A binding to {{: https://github.com/jedisct1/libsodium } libsodium}
    which wraps {{: http://nacl.cr.yp.to/ } NaCl} *)

(** Raised when decryption/authentication fails *)
exception VerificationFailure
(** Raised when provided keys are not valid *)
exception KeyError
(** Raised when provided nonce is not valid *)
exception NonceError

type public
type secret
type channel

type octets

module Serialize : sig
  module type S = sig
    type t

    val length : t -> int
    val of_octets : int -> octets -> t
    val into_octets : t -> int -> octets -> unit
  end

  module String : S with type t = string
  module Bigarray :
    S with type t = (char,
                     Bigarray.int8_unsigned_elt,
                     Bigarray.c_layout) Bigarray.Array1.t
  (*module Ctypes : S with type t = Unsigned.uchar Ctypes.Array.t*)
end

module Random : sig
  val stir : unit -> unit

  module Make : functor (T : Serialize.S) -> sig
    val gen : int -> T.t
  end
end

module Box : sig
  type 'a box_key
  type nonce
  type ciphertext

  type sizes = {
    public_key : int;
    secret_key : int;
    beforenm : int;
    nonce : int;
    zero : int;
    box_zero : int;
  }

  val bytes : sizes
  val crypto_module : string
  val ciphersuite : string
  val impl : string

  (** Overwrite the key with random bytes *)
  val wipe_key : 'a box_key -> unit

  val compare_keys : public box_key -> public box_key -> int

  module Make : functor (T : Serialize.S) -> sig
    val box_write_key : 'a box_key -> T.t
    (** Can raise {! exception : KeyError } *)
    val box_read_public_key : T.t -> public box_key
    (** Can raise {! exception : KeyError } *)
    val box_read_secret_key : T.t -> secret box_key
    (** Can raise {! exception : KeyError } *)
    val box_read_channel_key: T.t -> channel box_key

    val write_nonce : nonce -> T.t
    (** Can raise {! exception : NonceError } *)
    val read_nonce : T.t -> nonce

    val write_ciphertext : ciphertext -> T.t
    val read_ciphertext : T.t -> ciphertext

    val box_keypair : unit -> public box_key * secret box_key
    val box :
      secret box_key -> public box_key -> T.t -> nonce:nonce -> ciphertext
    (** Can raise {! exception : VerificationFailure } *)
    val box_open :
      secret box_key -> public box_key -> ciphertext -> nonce:nonce -> T.t
    val box_beforenm : secret box_key -> public box_key -> channel box_key
    val box_afternm : channel box_key -> T.t -> nonce:nonce -> ciphertext
    (** Can raise {! exception : VerificationFailure } *)
    val box_open_afternm : channel box_key -> ciphertext -> nonce:nonce -> T.t
  end
end