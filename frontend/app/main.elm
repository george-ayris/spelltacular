module Main exposing (main)

import Html exposing (Html, div, button, h1, text)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode
import List.Extra as ListE


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { currentPage : Page }


type Page
    = Home
    | LoadingSpellings
    | Spelling SpellingData
    | SpellingCompleted
    | Error String


type alias SpellingData =
    { spellings : List String, currentSpellingIndex : Int }


init : ( Model, Cmd Msg )
init =
    ( Model Home, Cmd.none )


type Msg
    = StartSpelling
    | SpellingsLoaded (Result Http.Error SpellingData)
    | NextSpelling SpellingData


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartSpelling ->
            ( { model | currentPage = LoadingSpellings }, loadSpellings )

        SpellingsLoaded result ->
            case result of
                Ok spellingData ->
                    ( { model | currentPage = Spelling spellingData }, Cmd.none )

                Err error ->
                    ( { model | currentPage = Error (toString error) }, Cmd.none )

        NextSpelling ({ spellings, currentSpellingIndex } as spellingData) ->
            let
                nextSpellingIndex =
                    currentSpellingIndex + 1
            in
                if nextSpellingIndex < List.length spellings then
                    ( { model | currentPage = Spelling { spellingData | currentSpellingIndex = nextSpellingIndex } }, Cmd.none )
                else
                    ( { model | currentPage = SpellingCompleted }, Cmd.none )


loadSpellings : Cmd Msg
loadSpellings =
    Http.send SpellingsLoaded (Http.get "http://localhost:5000/spellings" decodeSpellingsData)


decodeSpellingsData : Decode.Decoder SpellingData
decodeSpellingsData =
    Decode.map (\x -> SpellingData x 0) (Decode.list Decode.string)


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "Spelltacular" ]
        , renderPage model
        ]


renderPage : Model -> Html Msg
renderPage model =
    case model.currentPage of
        Home ->
            div []
                [ text "Welcome"
                , button [ onClick StartSpelling ] [ text "Start" ]
                ]

        LoadingSpellings ->
            div []
                [ text "Conjuring spellings" ]

        Spelling ({ spellings, currentSpellingIndex } as spellingData) ->
            div []
                [ text (Maybe.withDefault "ERROR" <| ListE.getAt currentSpellingIndex spellings)
                , button [ onClick <| NextSpelling spellingData ] [ text "Next" ]
                ]

        SpellingCompleted ->
            div [] [ text "Well done, spellings completed" ]

        Error errorMessage ->
            div [] [ text ("Error: " ++ errorMessage) ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
