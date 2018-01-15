(ns frontend.core
    (:require-macros [cljs.core.async.macros :refer [go]])
    (:require [reagent.core :as r]
              [reagent.ratom :as ratom]
              [cljs-http.client :as http]
              [cljs.core.async :refer [<!]]
              [cljs-time.core :as time]
              [clojure.string :as string]))

(enable-console-print!)
(set! *warn-on-infer* true)
(goog-define api-uri "http://localhost:3000")

(defonce spelling-input (r/atom ""))
(defonce spelling-started-time (r/atom nil))
(defonce spellings (r/atom []))
(defonce spelling-attempts (r/atom []))
(defonce spelling-index (r/atom 0))
(defonce current-spelling (ratom/reaction (get @spellings @spelling-index)))

(defn speak [text]
  (let [utterance (js/SpeechSynthesisUtterance. text)]
    (.speak (.-speechSynthesis js/window) utterance)))

(defn speak-current-spelling []
  (if (not (nil? @current-spelling))
    (speak @current-spelling))) 

(defn load-spellings [] 
  (go (let [response (<! (http/get (str api-uri "/spellings")
                                    {:with-credentials? false}))]
        (reset! spellings (:body response))
        (reset! spelling-started-time (time/now))
        (speak-current-spelling))))

(defn update-text [text]
  (reset! spelling-input text))

(defn record-spelling-attempt []
  (do
    (let [spelling-time (time/interval @spelling-started-time (time/now))]
      (swap! spelling-attempts conj {:spelling @spelling-input :time spelling-time}))
    (swap! spelling-index inc)
    (reset! spelling-input "")
    (reset! spelling-started-time (time/now))
    (speak-current-spelling))) 

(defn start-again []
  (do
    (reset! spellings [])
    (load-spellings)
    (reset! spelling-input "")
    (reset! spelling-index 0)
    (reset! spelling-attempts [])))

(defn is-spelling-correct [spelling attempt]
  (= spelling (string/trim attempt))) ;; should this also be case-insensitive?

(defn spelling-input-form []
     [:div 
       [:p @current-spelling]
       [:input {:type "text"
                :value @spelling-input
                :onChange (fn [e]
                              (update-text (.. e -target -value)))
                :onKeyPress (fn [e] 
                              (if (= (.. e -key) "Enter") 
                                 (record-spelling-attempt)
                                 true))}]
       [:input {:type "button"
                :value "Next"
                :onClick record-spelling-attempt}]])

(defn spellings-results [] 
  [:div 
    [:table 
      [:thead [:tr [:th "Spelling"] [:th "Attempt"] [:th "Correct"] [:th "Time (ms)"]]]
      [:tbody 
        (map (fn [spelling attempt] 
               [:tr 
                {:key spelling}
                [:td spelling] [:td (:spelling attempt)] [:td (str (is-spelling-correct spelling (:spelling attempt)))] [:td (time/in-millis (:time attempt))]])  
             @spellings 
             @spelling-attempts)]]
    [:input {:type "button"
             :value "Start again"
             :onClick start-again}]])

(defn render-app []
  [:div
   [:h1 "Spelltacular"]
   (if (empty? @spellings)
     [:div [:p "Loading spellings"]]
     (if (>= @spelling-index (count @spellings))
       [spellings-results]
       [spelling-input-form]))]) 

(load-spellings)
(r/render-component [render-app]
                          (. js/document (getElementById "app")))

;; should move to dev file
(defn on-js-reload []
  (do 
    (reset! spelling-index 0)
    (reset! spelling-attempts [])
    (reset! spelling-input "")
    (reset! spellings [])
    true)
  ;; optionally touch your app-state to force rerendering depending on
  ;; your application
  ;; (swap! app-state update-in [:__figwheel_counter] inc)
)
