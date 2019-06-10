module Modal exposing
    ( Model, init, subscriptions
    , Msg, update
    , view
    , openOnClick, closeOnClick
    , firstFocusableElement, lastFocusableElement, singleFocusableElement
    )

{-|

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
            , Cmd.none
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
    , title : ( String, List (Attribute Never) )
    , content : Html msg
    }
    -> Model
    -> Html msg
view config model =
    case model of
        Opened _ ->
            section
                [ Role.dialog
                , Aria.labeledBy modalTitleId
                ]
                [ map never (viewTitle config.title)
                , config.content
                ]

        Closed ->
            config.ifClosed


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
        [ Key.tabBack (Focus "modal__single-focusable-element")
        , Key.tab (Focus "modal__single-focusable-element")
        ]
    , id "modal__single-focusable-element"
    ]


{-| -}
firstFocusableElement : List (Attribute Msg)
firstFocusableElement =
    [ Key.onKeyDown [ Key.tabBack (Focus "modal__last-focusable-element") ]
    , id "modal__first-focusable-element"
    ]


{-| -}
lastFocusableElement : List (Attribute Msg)
lastFocusableElement =
    [ Key.onKeyDown [ Key.tab (Focus "modal__first-focusable-element") ]
    , id "modal__last-focusable-element"
    ]


{-| -}
subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        Opened _ ->
            Browser.Events.onKeyDown (Key.escape CloseModal)

        Closed ->
            Sub.none
