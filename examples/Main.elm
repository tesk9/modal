module Main exposing (main)

import Browser exposing (element)
import Html exposing (..)
import Modal
import Platform


main : Platform.Program {} Model Msg
main =
    element
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }


init : {} -> ( Model, Cmd Msg )
init flags =
    ( {}, Cmd.none )


type alias Model =
    {}


type Msg
    = Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Msg ->
            ( model, Cmd.none )


subscriptions : Model -> Sub msg
subscriptions model =
    Sub.none


view : Model -> Html Msg
view model =
    div [] []
