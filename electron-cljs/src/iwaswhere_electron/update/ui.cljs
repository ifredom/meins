(ns iwaswhere-electron.update.ui
  (:require-macros [reagent.ratom :refer [reaction]])
  (:require [reagent.core :as rc]
            [re-frame.core :refer [reg-sub subscribe]]
            [re-frame.db :as rdb]
            [iwaswhere-electron.update.log :as log]))

;; Subscription Handlers
(reg-sub :current-page (fn [db _] (:current-page db)))

(defn cancel-btn [put-fn]
  (let [cancel (fn [_]
                 (log/info "Cancel button clicked")
                 (put-fn [:window/close]))]
    [:button {:on-click cancel} "cancel"]))

(defn checking [put-fn]
  [:div.updater
   [:h1 "Checking for latest version of iWasWhere..."]
   [cancel-btn put-fn]])

(defn no-update [put-fn]
  (let [check (fn [_]
                (log/info "Check button clicked")
                (put-fn [:update/check]))]
    [:div.updater
     [:h1 "You already have the latest version of iWasWhere."]
     [cancel-btn put-fn]
     " "
     [:button {:on-click check} "check"]]))

(defn update-available [put-fn]
  (let []
    [:div.updater
     [:h1 "New version of iWasWhere available."]
     [cancel-btn put-fn]]))

(defn downloading [status-msg put-fn]
  (let [{:keys [total percent bytesPerSecond transferred]} (:info status-msg)
        mbs (/ (Math/floor (/ bytesPerSecond 1024 102.4)) 10)
        total (Math/floor (/ total 1024 1024))
        transferred (Math/floor (/ transferred 1024 1024))
        percent (Math/floor percent)]
    [:div.updater
     [:h1 "Downloading new version of iWasWhere."]
     [:div.meter
      [:span {:style {:width (str percent "%")}}]]
     [:div [:strong "Total size: "] total " MB"]
     [:div [:strong "Transferred: "] total " MB"]
     [:div [:strong "Progress: "] percent "%"]
     [:div [:strong "Speed: "] mbs " MB/s"]
     [cancel-btn put-fn]]))

(defn update-downloaded [put-fn]
  (let [install (fn [_]
                  (log/info "Install button clicked")
                  (put-fn [:update/install]))]
    [:div.updater
     [:h1 "New version of iWasWhere ready to install."]
     [cancel-btn put-fn]
     " "
     [:button {:on-click install} "install"]]))

(defn re-frame-ui
  "Main view component"
  [local put-fn]
  (let [current-page (subscribe [:current-page])]
    (fn [local put-fn]
      (let [status-msg (:status-msg @local)
            status (:status status-msg)]
        [:div.updater
         (case status
           :update/checking [checking put-fn]
           :update/not-available [no-update put-fn]
           :update/available [update-available put-fn]
           :update/downloading [downloading status-msg put-fn]
           :update/downloaded [update-downloaded put-fn]
           [:h1 "Updater: " (str status)])]))))

(defn state-fn
  "Renders main view component and wires the central re-frame app-db as the
   observed component state, which will then be updated whenever the store-cmp
   changes."
  [put-fn]
  (let [local (rc/atom {})]
    (rc/render [re-frame-ui local put-fn] (.getElementById js/document "app"))
    (put-fn [:update/check])
    {:observed rdb/app-db
     :state    local}))

(defn set-status
  [{:keys [current-state msg msg-type msg-meta msg-payload]}]
  (let [new-state (assoc-in current-state [:status-msg] msg-payload)]
    {:new-state new-state}))

(defn cmp-map
  [cmp-id]
  {:cmp-id      cmp-id
   :state-fn    state-fn
   :handler-map {:update/status set-status}})