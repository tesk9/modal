module Accessibility.Modal exposing
    ( Model, init, subscriptions
    , Msg, update, close, open
    , view, openOnClick
    , Autofocus(..), autofocusOnLastElement, custom, multipleFocusableElementView, onlyFocusableElementView, overlayColor, title, titleStyles
    )

{-|

    import Accessibility.Modal as Modal
    import Html exposing (..)
    import Html.Attributes exposing (style)
    import Html.Events exposing (onClick)

    view : Html Modal.Msg
    view =
        Modal.view identity
            "Example modal"
            [ Modal.onlyFocusableElementView
                (\onlyFocusableElementAttributes ->
                    div []
                        [ text "Welcome to this modal! I'm so happy to have you here with me."
                        , button
                            (onClick Modal.close :: onlyFocusableElementAttributes)
                            [ text "Close Modal" ]
                        ]
                )
            ]
            modal

@docs Model, init, subscriptions
@docs Msg, update, close, open
@docs view, openOnClick

-}

import Accessibility exposing (..)
import Accessibility.Aria as Aria
import Accessibility.Key as Key
import Accessibility.Role as Role
import Browser
import Browser.Dom exposing (focus)
import Browser.Events
import Html as Root
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


type By
    = EscapeKey
    | OverlayClick
    | Other


{-| -}
type Msg
    = OpenModal String
    | CloseModal By
    | Focus String
    | Focused (Result Browser.Dom.Error ())


{-| -}
update : { dismissOnEscAndOverlayClick : Bool } -> Msg -> Model -> ( Model, Cmd Msg )
update { dismissOnEscAndOverlayClick } msg model =
    case msg of
        OpenModal returnFocusTo ->
            ( Opened returnFocusTo
            , focus autofocusId
                |> Task.onError (\_ -> focus firstId)
                |> Task.attempt Focused
            )

        CloseModal by ->
            let
                closeModal returnFocusTo =
                    ( Closed, Task.attempt Focused (focus returnFocusTo) )
            in
            case ( model, by, dismissOnEscAndOverlayClick ) of
                ( Opened returnFocusTo, _, True ) ->
                    closeModal returnFocusTo

                ( Opened returnFocusTo, Other, False ) ->
                    closeModal returnFocusTo

                _ ->
                    ( model, Cmd.none )

        Focus id ->
            ( model, Task.attempt Focused (focus id) )

        Focused _ ->
            ( model, Cmd.none )


type Autofocus
    = Default
    | Last


type Config msg
    = Config
        { overlayColor : String
        , wrapMsg : Msg -> msg
        , modalAttributes : List (Attribute Never)
        , title : ( String, List (Attribute Never) )
        , autofocusOn : Autofocus
        , content :
            { onlyFocusableElement : List (Attribute msg)
            , firstFocusableElement : List (Attribute msg)
            , lastFocusableElement : List (Attribute msg)
            , autofocusOn : Attribute msg
            }
            -> Html msg
        }


defaults : (Msg -> msg) -> String -> Config msg
defaults wrapMsg t =
    Config
        { overlayColor = "rgba(128, 0, 70, 0.7)"
        , wrapMsg = wrapMsg
        , modalAttributes =
            [ style "background-color" "white"
            , style "border-radius" "8px"
            , style "border" "2px solid purple"
            , style "margin" "80px auto"
            , style "padding" "20px"
            , style "max-width" "600px"
            , style "min-height" "40vh"
            ]
        , title = ( t, [] )
        , autofocusOn = Default
        , content = \_ -> text ""
        }


{-| -}
overlayColor : String -> Config msg -> Config msg
overlayColor color (Config config) =
    Config { config | overlayColor = color }


{-| -}
title : String -> Config msg -> Config msg
title t (Config config) =
    Config { config | title = Tuple.mapFirst (\_ -> t) config.title }


{-| -}
titleStyles : List (Attribute Never) -> Config msg -> Config msg
titleStyles styles (Config config) =
    Config { config | title = Tuple.mapSecond (\_ -> styles) config.title }


{-| -}
custom : List (Attribute Never) -> Config msg -> Config msg
custom styles (Config config) =
    Config { config | modalAttributes = styles }


{-| -}
autofocusOnLastElement : Config msg -> Config msg
autofocusOnLastElement (Config config) =
    Config { config | autofocusOn = Last }


{-| -}
onlyFocusableElementView : (List (Attribute msg) -> Html msg) -> Config msg -> Config msg
onlyFocusableElementView v (Config config) =
    Config { config | content = \{ onlyFocusableElement } -> v onlyFocusableElement }


{-| -}
multipleFocusableElementView :
    ({ firstFocusableElement : List (Attribute msg)
     , lastFocusableElement : List (Attribute msg)
     , autofocusElement : Attribute msg
     }
     -> Html msg
    )
    -> Config msg
    -> Config msg
multipleFocusableElementView v (Config config) =
    Config
        { config
            | content =
                \{ firstFocusableElement, lastFocusableElement, autofocusOn } ->
                    v
                        { firstFocusableElement = firstFocusableElement
                        , lastFocusableElement = lastFocusableElement
                        , autofocusElement = autofocusOn
                        }
        }


{-| -}
view :
    (Msg -> msg)
    -> String
    -> List (Config msg -> Config msg)
    -> Model
    -> Html msg
view wrapMsg ti attributes model =
    let
        (Config config) =
            List.foldl (\f acc -> f acc) (defaults wrapMsg ti) attributes
    in
    case model of
        Opened _ ->
            div
                [ style "position" "fixed"
                , style "top" "0"
                , style "left" "0"
                , style "width" "100%"
                , style "height" "100%"
                ]
                [ viewBackdrop config
                , div (style "position" "relative" :: config.modalAttributes)
                    [ viewModal config ]
                , Root.node "style" [] [ text "body {overflow: hidden;} " ]
                ]

        Closed ->
            text ""


viewBackdrop :
    { a | wrapMsg : Msg -> msg, overlayColor : String }
    -> Html msg
viewBackdrop config =
    Root.div
        -- We use Root html here in order to allow clicking to exit out of
        -- the overlay. This behavior is available to non-mouse users as
        -- well via the ESC key, so imo it's fine to have this div
        -- be clickable but not focusable.
        [ style "position" "absolute"
        , style "width" "100%"
        , style "height" "100%"
        , style "background-color" config.overlayColor
        , onClick (config.wrapMsg (CloseModal OverlayClick))
        ]
        []


viewModal :
    { a
        | title : ( String, List (Attribute Never) )
        , wrapMsg : Msg -> msg
        , autofocusOn : Autofocus
        , content :
            { onlyFocusableElement : List (Attribute msg)
            , firstFocusableElement : List (Attribute msg)
            , lastFocusableElement : List (Attribute msg)
            , autofocusOn : Attribute msg
            }
            -> Html msg
    }
    -> Html msg
viewModal config =
    section
        [ Role.dialog
        , Aria.labeledBy modalTitleId
        ]
        [ map never (viewTitle config.title)
        , config.content
            (case config.autofocusOn of
                Last ->
                    { onlyFocusableElement =
                        [ Key.onKeyDown
                            [ Key.tabBack (Focus firstId)
                            , Key.tab (Focus firstId)
                            ]
                        , id firstId
                        ]
                            |> List.map (Html.Attributes.map config.wrapMsg)
                    , firstFocusableElement =
                        [ Key.onKeyDown [ Key.tabBack (Focus autofocusId) ]
                        , id firstId
                        ]
                            |> List.map (Html.Attributes.map config.wrapMsg)
                    , lastFocusableElement =
                        [ Key.onKeyDown [ Key.tab (Focus firstId) ]
                        , id autofocusId
                        ]
                            |> List.map (Html.Attributes.map config.wrapMsg)
                    , autofocusOn =
                        id autofocusId
                            |> Html.Attributes.map config.wrapMsg
                    }

                _ ->
                    { onlyFocusableElement =
                        [ Key.onKeyDown
                            [ Key.tabBack (Focus firstId)
                            , Key.tab (Focus firstId)
                            ]
                        , id firstId
                        ]
                            |> List.map (Html.Attributes.map config.wrapMsg)
                    , firstFocusableElement =
                        [ Key.onKeyDown [ Key.tabBack (Focus lastId) ]
                        , id firstId
                        ]
                            |> List.map (Html.Attributes.map config.wrapMsg)
                    , lastFocusableElement =
                        [ Key.onKeyDown [ Key.tab (Focus firstId) ]
                        , id lastId
                        ]
                            |> List.map (Html.Attributes.map config.wrapMsg)
                    , autofocusOn =
                        id autofocusId
                            |> Html.Attributes.map config.wrapMsg
                    }
            )
        ]


modalTitleId : String
modalTitleId =
    "modal__title"


firstId : String
firstId =
    "modal__first-focusable-element"


lastId : String
lastId =
    "modal__last-focusable-element"


autofocusId : String
autofocusId =
    "modal__autofocus-element"


viewTitle : ( String, List (Attribute Never) ) -> Html Never
viewTitle ( t, titleAttrs ) =
    h1
        (id modalTitleId :: titleAttrs)
        [ text t ]


{-| -}
openOnClick : (Msg -> msg) -> String -> List (Attribute msg)
openOnClick wrapMsg uniqueId =
    let
        elementId =
            "modal__launch-element-" ++ uniqueId
    in
    [ id elementId
    , Html.Attributes.map wrapMsg (onClick (OpenModal elementId))
    ]


{-| Pass the id of the element that should receive focus when the modal closes.
-}
open : String -> Msg
open =
    OpenModal


{-| -}
close : Msg
close =
    CloseModal Other


{-| -}
subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        Opened _ ->
            Browser.Events.onKeyDown (Key.escape (CloseModal EscapeKey))

        Closed ->
            Sub.none
