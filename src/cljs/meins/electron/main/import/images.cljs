(ns meins.electron.main.import.images
  (:require ["glob" :as glob :refer [sync]]
            ["fs" :refer [copyFileSync existsSync readFileSync]]
            [taoensso.timbre :refer [error info]]
            [clojure.string :as str]
            [meins.electron.main.helpers :as h]
            [cljs.spec.alpha :as spec]
            ["moment" :as moment]
            [clojure.pprint :as pp]
            [expound.alpha :as exp]
            [clojure.string :as s]))

(def image-path-atom (atom ""))

(defn convert-image-entry [data]
  (let [ts (get data "timestamp")
        text (str (h/format-time ts) " Image")
        geolocation (get data "geolocation")
        entry {:timestamp  ts
               :md         text
               :text       text
               :mentions   #{}
               :utc-offset 0
               :img_file   (s/replace (get data "imageFile") "HEIC" "JPG")
               :timezone   (get data "timezone")
               :tags       #{"#photo" "#import"}
               :perm_tags  #{"#photo"}
               :longitude  (get geolocation "longitude")
               :latitude   (get geolocation "latitude")
               :vclock     (get data "vectorClock")}]
    entry))

(defn convert-new-image-entry [json]
  (let [meta-data (get json "meta")
        date-from (get meta-data "dateFrom")
        entry-text-object (get json "entryText")
        plain-text (get entry-text-object "plainText")
        markdown (get entry-text-object "markdown")
        ts (.valueOf (moment date-from))
        data (get json "data")
        placeholder-text (str (h/format-time ts) " Image")
        geolocation (get json "geolocation")
        entry {:timestamp  ts
               :md         (or markdown placeholder-text)
               :text       (or plain-text placeholder-text)
               :mentions   #{}
               :utc-offset 0
               :img_file   (s/replace (get data "imageFile") "HEIC" "JPG")
               :timezone   (get meta-data "timezone")
               :tags       #{"#photo" "#import"}
               :perm_tags  #{"#photo"}
               :longitude  (get geolocation "longitude")
               :latitude   (get geolocation "latitude")
               :vclock     (get meta-data "vectorClock")}]
    entry))

(defn import-image-files [path put-fn]
  (let [files (sync (str path "/images/**/*.+(JPG|JPEG|jpg|jpeg).json"))]
    (doseq [json-file files]
      (when-not (s/includes? json-file "trash")
        (let [data (h/parse-json json-file)
              entry (convert-new-image-entry data)
              file (str/replace json-file ".json" "")
              img-file (:img_file entry)
              img-file-path (str @image-path-atom "/" img-file)]
          (info (exp/expound-str :meins.entry/spec entry))
          (when-not (existsSync img-file-path)
            (when (existsSync file)
              (info "importing" file)
              (js/setTimeout #(when (spec/valid? :meins.entry/spec entry)
                                (info "spec/valid")
                                (info file img-file-path)
                                (copyFileSync file img-file-path)
                                (put-fn [:import/gen-thumbs
                                         {:filename  img-file
                                          :full-path file}]))
                             2000)
              (js/setTimeout #(when (spec/valid? :meins.entry/spec entry)
                                (put-fn [:entry/save-initial entry]))
                             4000))))))))

