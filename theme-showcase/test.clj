(ns myapp.core
  (:require [ring.adapter.jetty :as jetty]
            [ring.middleware.json :as json]
            [compojure.core :refer [defroutes GET POST]]
            [compojure.route :as route]
            [clojure.data.json :as json-lib]))

;; Data structures and atoms for state management
(def users (atom {}))
(def next-id (atom 1))

;; Utility functions
(defn generate-id []
  (swap! next-id inc))

(defn find-user [id]
  (get @users (Integer/parseInt id)))

(defn valid-user? [user]
  (and (:name user)
       (:email user)
       (re-matches #".+@.+\..+" (:email user))))

;; Core business logic with higher-order functions
(defn create-user [user-data]
  (when (valid-user? user-data)
    (let [id (generate-id)
          user (assoc user-data :id id :created-at (java.time.Instant/now))]
      (swap! users assoc id user)
      user)))

(defn update-user [id updates]
  (when-let [existing-user (find-user id)]
    (let [updated-user (merge existing-user updates)]
      (when (valid-user? updated-user)
        (swap! users assoc (Integer/parseInt id) updated-user)
        updated-user))))

;; Collection processing with threading macros
(defn get-users-by-domain [domain]
  (->> @users
       vals
       (filter #(clojure.string/ends-with? (:email %) domain))
       (sort-by :created-at)
       (map #(select-keys % [:id :name :email]))))

;; Polymorphic function using multimethods
(defmulti format-response (fn [format _] format))

(defmethod format-response :json [_ data]
  {:status 200
   :headers {"Content-Type" "application/json"}
   :body (json-lib/write-str data)})

(defmethod format-response :html [_ data]
  {:status 200
   :headers {"Content-Type" "text/html"}
   :body (str "<h1>Users</h1><pre>" (pr-str data) "</pre>")})

;; Recursive function with lazy sequences
(defn fibonacci-seq
  ([] (fibonacci-seq 0 1))
  ([a b] (lazy-seq (cons a (fibonacci-seq b (+ a b))))))

(defn get-fibonacci [n]
  (->> (fibonacci-seq)
       (take n)
       vec))

;; Macro definition
(defmacro with-timing [expr]
  `(let [start# (System/nanoTime)
         result# ~expr
         end# (System/nanoTime)]
     (println "Execution time:" (/ (- end# start#) 1e6) "ms")
     result#))

;; Route handlers with destructuring
(defn handle-get-users [req]
  (let [{:keys [query-params]} req
        domain (get query-params "domain")]
    (if domain
      (format-response :json (get-users-by-domain domain))
      (format-response :json (vals @users)))))

(defn handle-create-user [{:keys [body]}]
  (if-let [user (create-user body)]
    (format-response :json user)
    {:status 400 :body "Invalid user data"}))

(defn handle-update-user [id {:keys [body]}]
  (if-let [user (update-user id body)]
    (format-response :json user)
    {:status 404 :body "User not found or invalid data"}))

;; Routes definition using Compojure
(defroutes app-routes
  (GET "/users" req (handle-get-users req))
  (POST "/users" req (handle-create-user req))
  (GET "/users/:id" [id] 
    (if-let [user (find-user id)]
      (format-response :json user)
      {:status 404 :body "User not found"}))
  (POST "/users/:id" [id :as req] (handle-update-user id req))
  (GET "/fibonacci/:n" [n] 
    (with-timing
      (format-response :json {:sequence (get-fibonacci (Integer/parseInt n))})))
  (route/not-found "404 - Page not found"))

;; Middleware stack
(def app
  (-> app-routes
      (json/wrap-json-body {:keywords? true})
      json/wrap-json-response))

;; Server configuration and startup
(defn start-server [port]
  (println "Starting server on port" port)
  (jetty/run-jetty app {:port port :join? false}))

;; Main function with command line argument parsing
(defn -main [& args]
  (let [port (if (first args) 
               (Integer/parseInt (first args)) 
               3000)]
    ;; Seed some initial data
    (create-user {:name "Alice Johnson" :email "alice@example.com"})
    (create-user {:name "Bob Smith" :email "bob@test.org"})
    (create-user {:name "Charlie Brown" :email "charlie@example.com"})
    
    (println "Sample users created")
    (println "Available endpoints:")
    (println "  GET /users")
    (println "  POST /users")
    (println "  GET /users/:id")
    (println "  POST /users/:id")
    (println "  GET /fibonacci/:n")
    
    (start-server port)))

;; Example of using protocols
(defprotocol Drawable
  (draw [this]))

(defrecord Circle [radius color]
  Drawable
  (draw [this]
    (str "Drawing a " color " circle with radius " radius)))

(defrecord Rectangle [width height color]
  Drawable
  (draw [this]
    (str "Drawing a " color " rectangle " width "x" height)))

;; Usage examples in comments:
;; (def circle (->Circle 5 "red"))
;; (draw circle)
;; (def rect (map->Rectangle {:width 10 :height 5 :color "blue"}))
;; (draw rect)
