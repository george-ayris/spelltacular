(ns frontend2.core
    (:require-macros [cljs.core.async.macros :refer [go]])
    (:require [reagent.core :as r]
              [reagent.ratom :as ratom]
              [cljs-http.client :as http]
              [cljs.core.async :refer [<!]]
              [cljs-time.core :as time]))

(enable-console-print!)

;; define your app data so that it doesn't get over-written on reload

(defonce spelling-input (r/atom ""))
(defonce spelling-started-time (r/atom nil))
(defonce spellings (r/atom []))
(defonce spelling-attempts (r/atom []))
(defonce spelling-index (r/atom 0))
(defonce current-spelling (ratom/reaction (get @spellings @spelling-index)))

(defn load-spellings [] 
  (go (let [response (<! (http/get "http://localhost:5000/spellings"
                                    {:with-credentials? false}))]
        (do
          (reset! spellings (:body response))
          (reset! spelling-started-time (time/now))))))

(defn update-text [text]
  (reset! spelling-input text))

(defn record-spelling-attempt []
  (do
    (let [spelling-time (time/interval @spelling-started-time (time/now))]
      (swap! spelling-attempts conj {:spelling @spelling-input :time spelling-time}))
    (swap! spelling-index inc)
    (reset! spelling-input "")
    (reset! spelling-started-time (time/now)))) 

(defn spelling-input-form []
     [:div 
       [:p @current-spelling]
       [:input {:type "text"
                :value @spelling-input
                :onChange (fn [e]
                              (update-text (.. e -target -value)))}]
       [:input {:type "button"
                :value "Next"
                :onClick record-spelling-attempt}]])

(defn spellings-results [] 
  [:div
    [:div "Spelling | Attempt | Correct | Time (ms)"] 
    (map (fn [spelling attempt] 
           [:div {:key spelling} spelling " | " (:spelling attempt) " | " (str (= spelling (:spelling attempt)) " | " (time/in-millis (:time attempt)))]) 
         @spellings 
         @spelling-attempts)])

(defn render-app []
  [:div
   [:h1 "Spelltacular"]
   (if (empty? @spellings)
     [:div [:p "Loading spellings"]]
     (if (>= @spelling-index (count @spellings))
       (spellings-results)
       (spelling-input-form)))]) 

(load-spellings)
(r/render-component [render-app]
                          (. js/document (getElementById "app")))

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
