module Modal exposing
    ( Model, init, subscriptions
    , Msg, update
    , view
    , openOnClick, closeOnClick
    , firstFocusableElement, lastFocusableElement, singleFocusableElement
    )

{-|

    import Html exposing (..)
    import Html.Attributes exposing (style)
    import Modal

    view modalState =
        Modal.view
            { ifClosed =
                button (Modal.openOnClick "intro-modal")
                    [ text "Launch intro modal" ]
            , overlayColor = "rgba(128, 0, 128, 0.7)"
            , modalContainer =
                div
                    [ style "background-color" "white"
                    , style "border-radius" "4px"
                    , style "border" "2px solid purple"
                    , style "margin" "40px auto"
                    , style "padding" "20px"
                    , style "max-width" "600px"
                    , style "min-height" "40vh"
                    ]
            , title = ( "Intro Modal", [] )
            , content =
                div
                    [ style "display" "flex"
                    ]
                    [ text "Welcome to this modal! I'm so happy to have you here with me."
                    , button
                        (Modal.closeOnClick :: Modal.singleFocusableElement)
                        [ text "Close intro modal" ]
                    ]
            }
            modalState

@docs Model, init, subscriptions
@docs Msg, update
@docs view
@docs openOnClick, closeOnClick
@docs firstFocusableElement, lastFocusableElement, singleFocusableElement

-}

import Accessibility exposing (..)
import Accessibility.Aria as Aria
import Accessibility.Key as Key
import Accessibility.Role as Role
import Browser
import Browser.Dom exposing (focus)
import Browser.Events
import Html.Attributes exposing (id, style)
import Html.Events exposing (onClick)
import Task


{-| -}
type Model
    = Opened String
    | Closed


{-| -}
init : Model
init =
    Closed


{-| -}
type Msg
    = OpenModal String
    | CloseModal
    | Focus String
    | Focused (Result Browser.Dom.Error ())


{-| -}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OpenModal returnFocusTo ->
            ( Opened returnFocusTo
            , Task.attempt Focused (focus firstId)
            )

        CloseModal ->
            case model of
                Opened returnFocusTo ->
                    ( Closed, Task.attempt Focused (focus returnFocusTo) )

                Closed ->
                    ( Closed, Cmd.none )

        Focus id ->
            ( model, Task.attempt Focused (focus id) )

        Focused _ ->
            ( model, Cmd.none )


{-| -}
view :
    { ifClosed : Html msg
    , overlayColor : String
    , modalContainer : List (Html msg) -> Html msg
    , title : ( String, List (Attribute Never) )
    , content : Html msg
    }
    -> Model
    -> Html msg
view config model =
    case model of
        Opened _ ->
            div
                [ style "position" "fixed"
                , style "top" "0"
                , style "left" "0"
                , style "width" "100%"
                , style "height" "100%"
                , style "background-color" config.overlayColor
                ]
                [ config.modalContainer [ viewModal config ]
                ]

        Closed ->
            config.ifClosed


viewModal :
    { a
        | title : ( String, List (Attribute Never) )
        , content : Html msg
    }
    -> Html msg
viewModal config =
    section
        [ Role.dialog
        , Aria.labeledBy modalTitleId
        ]
        [ map never (viewTitle config.title)
        , config.content
        ]


viewTitle : ( String, List (Attribute Never) ) -> Html Never
viewTitle ( title, titleAttrs ) =
    h1
        (id modalTitleId :: titleAttrs)
        [ text title ]


modalTitleId : String
modalTitleId =
    "modal__title"


{-| -}
openOnClick : String -> List (Attribute Msg)
openOnClick uniqueId =
    let
        elementId =
            "modal__launch-element-" ++ uniqueId
    in
    [ id elementId
    , onClick (OpenModal elementId)
    ]


{-| -}
closeOnClick : Attribute Msg
closeOnClick =
    onClick CloseModal


{-| -}
singleFocusableElement : List (Attribute Msg)
singleFocusableElement =
    [ Key.onKeyDown
        [ Key.tabBack (Focus firstId)
        , Key.tab (Focus firstId)
        ]
    , id firstId
    ]


{-| -}
firstFocusableElement : List (Attribute Msg)
firstFocusableElement =
    [ Key.onKeyDown [ Key.tabBack (Focus lastId) ]
    , id firstId
    ]


{-| -}
lastFocusableElement : List (Attribute Msg)
lastFocusableElement =
    [ Key.onKeyDown [ Key.tab (Focus firstId) ]
    , id lastId
    ]


firstId : String
firstId =
    "modal__first-focusable-element"


lastId : String
lastId =
    "modal__last-focusable-element"


{-| -}
subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        Opened _ ->
            Browser.Events.onKeyDown (Key.escape CloseModal)

        Closed ->
            Sub.none