module Crypto.SHA.Preprocess exposing (calculateK, preprocess)

{-| SHA-2 preprocess.

    import Byte
    import Word.Bytes exposing (fromUTF8)
    import Crypto.SHA.Alg exposing (Alg(..))

-}

import Byte exposing (Byte)
import Crypto.SHA.Alg exposing (Alg(..))
import Crypto.SHA.Chunk as Chunk
import Word.Bytes as Bytes


{-| Append 1 + K zeros + size of message.

    preprocess SHA256 []
    --> 0x80 :: (List.repeat 63 0x00) |> List.map Byte.fromInt

    preprocess SHA512 []
    --> 0x80 :: (List.repeat 127 0x00) |> List.map Byte.fromInt

    let
        x = preprocess SHA256 (fromUTF8 "I ❤ cheese")
        y = preprocess SHA512 (fromUTF8 "I ❤ cheese")
    in
        ( x |> List.length
        , y |> List.length
        , x |> List.reverse |> List.head
        , y |> List.reverse |> List.head
        )
    --> ( 64
    --> , 128
    --> , Just <| Byte.fromInt ((9 + 3) * 8)
    --> , Just <| Byte.fromInt ((9 + 3) * 8)
    --> )

-}
preprocess : Alg -> List Byte -> List Byte
preprocess alg message =
    List.append message <| postfix alg (8 * List.length message)


postfix : Alg -> Int -> List Byte
postfix alg messageSize =
    List.concat
        [ [ Byte.fromInt 0x80 ]
        , List.repeat ((calculateK alg messageSize - 7) // 8) (Byte.fromInt 0x00)
        , Bytes.fromInt (messageSizeBytes alg) messageSize
        ]


{-| Calculate the amount of 0 bit padding.

    calculateK SHA256 0
    --> (512 - 64 - 1)

    calculateK SHA256 (512 - 64 - 1)
    --> 0

    calculateK SHA512 (1024 - 128 - 1)
    --> 0

    calculateK SHA256 (512 - 64 - 1 + 8)
    --> (512 - 8)

    calculateK SHA256 (512 - 64 - 1 - 8)
    --> 8

    calculateK SHA384 (1024 - 128 - 1 + 16)
    --> (1024 - 16)

    calculateK SHA384 (1024 - 128 - 1 - 16)
    --> 16

-}
calculateK : Alg -> Int -> Int
calculateK alg l =
    let
        c =
            Chunk.sizeInBits alg
    in
    (c
        - 1
        - (8 * messageSizeBytes alg)
        - (l % c)
    )
        % c


messageSizeBytes : Alg -> Int
messageSizeBytes alg =
    case alg of
        SHA224 ->
            messageSizeBytes SHA256

        SHA256 ->
            8

        SHA384 ->
            messageSizeBytes SHA512

        SHA512 ->
            16
