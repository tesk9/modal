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
    ( { modal = Modal.init
      }
    , Cmd.none
    )


type alias Model =
    { modal : Modal.Model
    }


type Msg
    = ModalMsg Modal.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ModalMsg modalMsg ->
            let
                ( newModalState, modalCmd ) =
                    Modal.update modalMsg model.modal
            in
            ( { model | modal = newModalState }
            , Cmd.map ModalMsg modalCmd
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map ModalMsg (Modal.subscriptions model.modal)


view : Model -> Html Msg
view model =
    div
        []
        [ button [] [ text "Supports focus" ]
        , Html.map ModalMsg (Modal.view model.modal)
        , button [] [ text "Supports focus" ]
        ]
