#!/usr/bin/env bb
(ns petardo.freereolen
  (:require [babashka.curl :as curl]
            [clojure.java.shell :refer [sh]]
            [cheshire.core :as json]))

(defn mktemp
  []
  (clojure.string/trim (:out (sh "mktemp"))))

(def cookie-jar (atom (mktemp)))

(defn make-cookie-jar
  []
  (reset! cookie-jar (mktemp)))

(defn request*
  ([method url] (request* method url nil))
  ([method url opts] (curl/request (-> opts
                              (assoc
                                :url      url
                                :method   method
                                :raw-args ["--cookie"     @cookie-jar
                                           "--cookie-jar" @cookie-jar])))))



(defn get-login-form-id
  []
  (request* :get "https://ereolen.dk/")
  (-> (request* :post "https://ereolen.dk/login/ajax")
    :body
    (json/parse-string)
    (->> (filter (fn [{:strs [title]}]
                (= title "Log ind"))))
    (first)
    (get "data")
    (->> (re-find #"name=\"form_build_id\" value=\"([^\"]+)\"" ))
    (second))
)

(defn login
  []
  (request* :post "https://ereolen.dk/system/ajax"
  {:form-params {"form_id"     "user_login"
                 "name"        "CPR"
                 "pass"        "PASSWORD"
                 "retailer_id" 810
                 "form_build_id" (get-login-form-id)}}))

(comment
  (->> tmp
    :body
    (spit "/tmp/body"))

  (def tmp (slurp "/tmp/body"))
  (-> (json/parse-string tmp)
    (->> (filter (fn [{:strs [title]}]
                   (= title "Log ind"))))
    (first)
    (get "data")
    (->> (re-find #"name=\"form_build_id\" value=\"([^\"]+)\"" ))
    (second)
    ))

(comment
  (def tmp2 (slurp "/tmp/me2.html"))

  (require '[clojure.data.xml :as xml])
  (xml/parse-str "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML+RDFa 1.0//EN\"
          \"http://www.w3.org/MarkUp/DTD/xhtml-rdfa-1.dtd\">
")

  (def x (xml/parse-str (->> tmp2
                          (clojure.string/split-lines)
                          (drop 2)
                          (clojure.string/join "\n"))))

  (clojure.string/join "\n" ["asd" "ads"])

  (->> x
    (take 4)
    )

  (-> x
    :content
    second
    :content
    (nth 3)
    )

  (clojure.walk/walk
    (fn [[k v]]))

  (-> x
    :first)

  (def tmp3 (xml/parse-str (slurp "/tmp/me3.html")))

  (clojure.walk/postwalk type tmp3))

;; #xml/element
;; {:tag :div,
;;  :attrs {:class "panel-pane pane-page-tabs"},
;;  :content
;;  ["\n\n\n  "
;;   #xml/element
;;   {:tag :div,
;;    :attrs {:class "pane-content"},
;;    :content
;;    ["\n    "
;;     #xml/element
;;     {:tag :div,
;;      :attrs {:id "tabs"},
;;      :content
;;      [#xml/element {:tag :h2,
;;                     :attrs {:class "element-invisible"},
;;                     :content ["Primære faneblade"]}
;;       #xml/element {:tag :ul,
;;                     :attrs {:class "tabs primary"},
;;                     :content [#xml/element{:tag :li,
;;                                            :attrs {:class "active"},
;;                                            :content [#xml/element{:tag :a,
;;                                                                   :attrs {:href "/user/me", :class "active"},
;;                                                                   :content ["Lån og reservationer" #xml/element{:tag :span,
;;                                                                                                                 :attrs {:class "element-invisible"},
;;                                                                                                                 :content ["(aktiv fane)"]}]}]}
;;                               "\n      "
;;                               #xml/element{:tag :li,
;;                                            :content [#xml/element{:tag :a,
;;                                                                   :attrs {:href "/user/me/edit"},
;;                                                                   :content ["Brugerprofil"]}]}
;;                               "\n      "
;;                               #xml/element{:tag :li,
;;                                            :content [#xml/element{:tag :a,
;;                                                                   :attrs {:href "/user/me/bookmarks"},
;;                                                                   :content ["Huskeliste (10)"]}]}
;;                               "\n      "
;;                               #xml/element{:tag :li,
;;                                            :content [#xml/element{:tag :a,
;;                                                                   :attrs {:href "/user/me/logout"},
;;                                                                   :content ["Log ud"]}]}
;;                               "\n    "]}]}
;;     "  "]}
;;   "\n"]}


(when nil
  (defn find*
    [pred node]
    (if (= "class clojure.data.xml.node.Element" (str (type node)))
      (do
        ;; (prn node)
        (filter seq (map (partial find* pred) (:content node))))
      (do
        (prn node)
        (if (pred node)
          (do
            (prn node)
            node)))))

  (defn find*
    [pred node]
    (if (pred node)
      node
      (filter seq (map (partial find* pred) (:content node)))))

  (doall
    (find* (fn [x] (= (:attrs x) {:class "item-information-list"}))
      (xml/parse-str (slurp "/tmp/me2.html"))))

  (= "class clojure.data.xml.node.Element" (str(type (xml/parse-str (slurp "/tmp/me3.html")))))


  ((fn [x] (= (:content x) ["Log ud"])) (xml/parse-str "<a href=\"/user/me/logout\">Log ud</a>")))
