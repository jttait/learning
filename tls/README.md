# Transport Layer Security (TLS)

TLS is a protocol that uses cryptography to secure communications over an insecure network. The
internet is an example of an insecure network. Secure communication means that messages cannot be
read or modified.

TLS is the successor to the deprecated SSL protocol. The most widely-known application is HTTPS but
it is just a cryptographic layer that sits on top of TCP.

## Public Key Cryptography

Cryptography uses a key to convert some data into an encrypted form.

Symmetric encryption is where both sender and receiver use the same key to encrypt and decrypt the
data. This is fast but requires sharing the key. There's no good way of sharing this key
electronically without encryption in the first place.

Asymmetric encryption solves this problem. With asymmetric encryption, there are two keys. These
keys are different but are linked in such a way that anything encrypted with one key can only be
decrypted with the other key. This is called a "key pair". The "public key" can be shared
everywhere. The "private key" must be kept secret.

You can encrypt something with your private key and then publish it. This isn't secure as anyone
with the public key can decrypt it but it can be used to prove you are who you say you are. If it
can be decrypted with your public key then it must have been encrypted with your private key and
you are the only one with access to your private key.

You can encrypt something with your private key and then with someone else's public key and then
send it to them. Then both parties know that no-one else can read the message and also that the
sender is who they claim to be. No-one else can read the message because it can only be decrypted
using the recipient's private key.

## X509 Certificates

Certificates are data structures for identity presentation and verification. An X509 certificate
binds an identity to a public key using a digital signature. Serial number is a unique number among
the certificates issued by the same issuer. Signature algorithm is the cryptographic hash function
and digital signature algorithm used to sign the certificate. Similar to public and private keys,
X509 certificates are encoded using ASN.1 into DER or PEM format.

Subject and Issuer fields are in the Distinguished Name (DN) format. DN consists of key-value pairs
with keys including Country (C), Organization (O), and Common Name (CN).

Every X509 certificate has a corresponding private key that matches the public key in the
certificate. The digital signature produced by the private key can be verified using the public key
in the certificate. An X509 certificate is not secret and can be distributed like a public key.

A certificate can be signed by it's own private key - this is known as a "self-signed certificate".
Self-signed certificates have the same DN in the Subject and Issuer fields. A certificate can also
be signed by another certificate and that certificate can be used to sign another certificate and so
on. Then we have a certificate signing chain.

A certificate signing chain is an ordered list of certificates where each certificate is signed by
the previous certificate in the list - except the first one which must be self-signed.

To verify a certificate, you must be build a certificate signing chain that ends with a certificate
that you already trust. Certificates that do not sign other certificates are called Leaf
Certificates. Certificates that both signed by other certificates and sign other certificates are
called Intermediate CA Certificates. Self-signed certificates that sign other certificates are
called Root CA Certificates.

We could sign all certificates with the Root CA Certificate but there are practical reasons why we
usually don't. If an Intermediate CA Certificate is compromised then revoking it will have less
impact than revoking the Root CA Certificate. If the Root CA Certificate is not used to sign other
certificates often then it can be stored more securely e.g. offline on an USB drive in a locked
safe. Certificate revocation lists can be smaller if they are done on an Intermediate CA Certificate
rather than the Root CA Certificate.

## Structure of an X509 Certificate

- Certificate
  - Data
    - Version
    - Serial Number
    - Signature Algorithm ID
    - Issuer
    - Validity
      - Not Before
      - Not After
    - Subject
    - Subject Public Key Info
    - X509 Extensions
  - Signature Algorithm

## Signing X509 Certificates

- Applicant generates private and public keys
- Applicant generates Certificate Signing Request (CSR) which is signed by private key
- Applicant sends CSR to Certicate Authority (CA)
- CA generates certificate using CSR, adds Issuer, Validity, etc, and signs certificate
- CA sends certificate to applicant

## Cipher Suite

A cipher suite has eight parts:

- Protocol e.g. TLS
- Key exchange algorithm
- Authentication mechanism during handshake
- Session cipher
- Session encryption key size in bits for cipher
- Type of encryption
- Hash function
- Digest size in bits

An example would be TLS\_ECDHE\_RSA\_AES\_128\_GCM\_SHA\_256.

## Message Digests

Message digests are also known as cryptographic hashes. In cryptography, a "message" is data that
is processed by a cryptographic algorithm. A cryptographic hash function is an algorithm that maps
a message to a relatively short fixed-size array of bits e.g. 256 bits. This fixed-size bit array is
called a message digest.

A cryptographic hash function has the following features:

- Deterministic: the same input always produces the same output
- Irreversible: impossible to recover the original message from it's digest
- Collision-free: impossible to have two distinct messges with the same digest
- Any change in the message will result in a large change to the digest

Message digests are used for Hash-based Message Authentication Code (HMAC) digital signatures.

The two most important attacks on cryptographic hash functions are collision attacks and pre-image
attacks. A collision attack tries to find two messages that produce the same message digest. A
pre-image attack tries to find a message that produces a pre-defined message digest.

The security level of a cryptographic hash function is the computational complexity of a collision
attack. If it takes 2<sup>128</sup> hash evaluations to find a collision then the security level is
128 bits. This is not the same as the size of the message digest e.g. SHA-256 has a 256-bit message
digest but a security level of 128 bit.

Cryptographic hash algorithms include SHA-2, SHA-3, MD2, MD4, MD5, MD6, BLAKE2, BLAKE3. If you can,
use SHA3-256.

## MAC and HMAC

A Message Authentication Code (MAC) is a short array of bits that authenticats a message. Message
authentication means that the receiver can verify that the message was sent by the stated sender and
was not modified during transmission.

The sender uses a MAC function to generate the MAC using a secret key. To verify the message, the
receiver needs the message and the same secret key.

The difference between a MAC and a message digest is a MAC protects against forgery. An attacker
could modify the message and recalculate the digest so that changed message matches the changed
digest. However, they could not regenerate the MAC as they don't have the secret key. Message
digests provide integrity whereas MACs provide integrity and authenticity.

HMAC is Hash-based MAC. HMAC uses a cryptographic hash function and secret key.

## Digital Signatures

A digital signature is an array of bits that provides crpytographically strong guarantees of
authenticity, integrity, and non-repudiation of a digital message.

Authenticity means that the message is coming from the claimed sender.

Integrity means that the message was not changed by a third-party during transmission.

Non-repudiation means that the sender cannot deny that they produced the message.

A digital signature is produced by a private key and can be verified by the corresponding
public key.

MACs use symmetric encryption. Digital signatures use asymmetric encryption. Digital signatures
provide non-repudiation, MACs do not.

Digital signatures algorithms include RSA, DSA, ECDSA, EdDSA, SM2.


