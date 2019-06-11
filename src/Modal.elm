module Modal exposing
    ( Model, init, subscriptions
    , Msg, update, close
    , view
    , openOnClick
    , firstFocusableElement, lastFocusableElement, singleFocusableElement
    )

{-|

    import Html exposing (..)
    import Html.Attributes exposing (style)
    import Html.Events exposing (onClick)
    import Modal

    view : Modal.State -> Html Modal.Msg
    view modalState =
        Modal.view
            { overlayColor = "rgba(128, 0, 128, 0.7)"
            , wrapMsg = identity
            , modalAttributes =
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
                        (onClick Modal.close :: Modal.singleFocusableElement)
                        [ text "Close intro modal" ]
                    ]
            }
            { dismissOnEscAndOverlayClick = False }

@docs Model, init, subscriptions
@docs Msg, update, close
@docs view
@docs openOnClick
@docs firstFocusableElement, lastFocusableElement, singleFocusableElement

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
type alias Model =
    { state : State
    , dismissOnEscAndOverlayClick : Bool
    }


{-| -}
type State
    = Opened String
    | Closed


{-| -}
init : { dismissOnEscAndOverlayClick : Bool } -> Model
init { dismissOnEscAndOverlayClick } =
    { state = Closed
    , dismissOnEscAndOverlayClick = dismissOnEscAndOverlayClick
    }


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
            ( { model | state = Opened returnFocusTo }
            , Task.attempt Focused (focus firstId)
            )

        CloseModal ->
            case model.state of
                Opened returnFocusTo ->
                    ( { model | state = Closed }, Task.attempt Focused (focus returnFocusTo) )

                Closed ->
                    ( { model | state = Closed }, Cmd.none )

        Focus id ->
            ( model, Task.attempt Focused (focus id) )

        Focused _ ->
            ( model, Cmd.none )


{-| -}
view :
    { overlayColor : String
    , wrapMsg : Msg -> msg
    , modalAttributes : List (Attribute Never)
    , title : ( String, List (Attribute Never) )
    , content : Html msg
    }
    -> Model
    -> Html msg
view config model =
    case model.state of
        Opened _ ->
            div
                [ style "position" "fixed"
                , style "top" "0"
                , style "left" "0"
                , style "width" "100%"
                , style "height" "100%"
                ]
                [ viewBackdrop config model.dismissOnEscAndOverlayClick
                , div (style "position" "relative" :: config.modalAttributes)
                    [ viewModal config ]
                , Root.node "style" [] [ text "body {overflow: hidden;} " ]
                ]

        Closed ->
            text ""


viewBackdrop :
    { a | wrapMsg : Msg -> msg, overlayColor : String }
    -> Bool
    -> Html msg
viewBackdrop config dismissOnEscAndOverlayClick =
    Root.div
        -- We use Root html here in order to allow clicking to exit out of
        -- the overlay. This behavior is available to non-mouse users as
        -- well via the ESC key, so imo it's fine to have this div
        -- be clickable but not focusable.
        ([ style "position" "absolute"
         , style "width" "100%"
         , style "height" "100%"
         , style "background-color" config.overlayColor
         ]
            ++ (if dismissOnEscAndOverlayClick then
                    [ onClick (config.wrapMsg close) ]

                else
                    []
               )
        )
        []


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
close : Msg
close =
    CloseModal


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
    case ( model.state, model.dismissOnEscAndOverlayClick ) of
        ( Opened _, True ) ->
            Browser.Events.onKeyDown (Key.escape CloseModal)

        _ ->
            Sub.none
