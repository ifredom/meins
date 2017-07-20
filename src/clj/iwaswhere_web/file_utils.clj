(ns iwaswhere-web.file-utils
  (:require [clj-uuid :as uuid]
            [clj-time.core :as time]
            [clj-time.format :as tf]
            [clojure.tools.logging :as log]
            [matthiasn.systems-toolbox.component :as st]
            [me.raynes.fs :as fs]
            [clojure.java.io :as io]
            [clojure.edn :as edn]
            [clojure.tools.logging :as l]
            [clojure.pprint :as pp]))

(def data-path (or (System/getenv "DATA_PATH") "data"))
(def daily-logs-path (str data-path "/daily-logs/"))
(def clucy-path (str data-path "/clucy/"))
(def export-path (str data-path "/export/"))

(defn paths []
  (let [trash-path (str data-path "/trash/")]
    (fs/mkdirs daily-logs-path)
    (fs/mkdirs clucy-path)
    (fs/mkdirs export-path)
    (fs/mkdirs trash-path)
    {:data-path       data-path
     :daily-logs-path daily-logs-path
     :clucy-path      clucy-path
     :export-path     export-path
     :trash-path      trash-path}))

(defn load-cfg
  "Load config from file. When not exists, use default config and write the
   default to data path."
  []
  (let [conf-path (str data-path "/conf.edn")
        default (edn/read-string (slurp (io/resource "default-conf.edn")))
        questionnaires (edn/read-string (slurp (io/resource "questionnaires.edn")))
        conf (try (edn/read-string (slurp conf-path))
                  (catch Exception ex
                    (do (log/warn "No config found -> copying from default.")
                        (fs/mkdirs data-path)
                        (spit conf-path (with-out-str (pp/pprint default)))
                        default)))]
    (update-in conf [:questionnaires] #(merge-with merge questionnaires %))))
