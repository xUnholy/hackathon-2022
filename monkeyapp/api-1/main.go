package main

import (
	"crypto/tls"
	"fmt"
	"golang.org/x/net/http2"
	"html/template"
	"log"
	"math/rand"
	"net"
	"net/http"
	"net/http/httputil"
	"os"
	"time"
)

type Spec struct {
	Name string
	Node string
}

func healthCheck(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "alive")
	fmt.Println("alive")
}

func readyCheck(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "ready")
	fmt.Println("ready")
}

func headerDump(w http.ResponseWriter, r *http.Request) {
	requestDump, err := httputil.DumpRequest(r, true)
	if err != nil {
		fmt.Println(err)
	}
	headers := string(requestDump)
	fmt.Println(headers)
	fmt.Fprintf(w, headers)
}

func headerDumpCallApi2(w http.ResponseWriter, r *http.Request) {
	requestDump, err := httputil.DumpRequest(r, true)
	//api2Response,err := http.Get("http://api-2.api-2.svc.cluster.local:7777/headers")
	log.Println("headerdump call api 2 invokec")
	clientUrl := "http://api-2.api-2.svc.cluster.local:7777/headers"
	client := &http.Client{}
	clientRequest, _ := http.NewRequest("GET", clientUrl, nil)
	//clientRequest.Header.Set("X-Request-Id", r.Header.Get("X-Request-Id"))
	//clientRequest.Header.Set("X-B3-Spanid", r.Header.Get("X-B3-Spanid"))
	//clientRequest.Header.Set("X-B3-Traceid", r.Header.Get("X-B3-Traceid"))
	//clientRequest.Header.Set("traceparent", r.Header.Get("traceparent"))
	api2Response, _ := client.Do(clientRequest)

	//api2Response,err := http.Get("http://api-1.minikube:30995/callapi-2")

	if err != nil {
		fmt.Println(err)
	}
	headers := string(requestDump)
	fmt.Println(headers, api2Response)
	fmt.Fprintf(w, headers, api2Response)
}

func headerDumpCallApi3(w http.ResponseWriter, r *http.Request) {

	client := http.Client{
		Transport: &http2.Transport{
			// So http2.Transport doesn't complain the URL scheme isn't 'https'
			AllowHTTP: true,
			// Pretend we are dialing a TLS endpoint.
			// Note, we ignore the passed tls.Config
			DialTLS: func(network, addr string, cfg *tls.Config) (net.Conn, error) {
				return net.Dial(network, addr)
			},
		},
	}
	requestDump, err := httputil.DumpRequest(r, true)

	api3Response, err := client.Get("http://api-3.api-3.svc.cluster.local:7777/am")

	if err != nil {
		fmt.Println(err)
	}
	headers := string(requestDump)
	fmt.Println(headers, api3Response)
	fmt.Fprintf(w, headers, api3Response)
}

func helloHandler(w http.ResponseWriter, r *http.Request) {
	//title := r.URL.Path[len("/hello/"):]
	//fmt.Fprintf(w, "Hi there, I love %s!", title)

	requestDump, err := httputil.DumpRequest(r, true)
	if err != nil {
		fmt.Println(err)
	}
	//fmt.Println(string(requestDump))
	no := rand.Intn(10)
	fmt.Println("Request received", time.Now())
	//time.Sleep(2 * time.Second)
	fmt.Println("after sleep", time.Now())
	if no%2 == 0 {
		w.WriteHeader(http.StatusServiceUnavailable)
		fmt.Println("Service Unavailable")
		fmt.Println(string(requestDump))
	} else {
		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, "Excellent job Zoli, request is OK")
		fmt.Println("Service OK")
		fmt.Println(string(requestDump))
	}
}

func viewHandler2(w http.ResponseWriter, r *http.Request) {
	title := r.URL.Path[len("/hello/"):]
	fmt.Fprintf(w, "Hi there, I love %s!", title)

}

func main() {
	//http.HandleFunc("/hello", helloHandler)
	http.HandleFunc("/healthz", healthCheck)
	http.HandleFunc("/ready", readyCheck)
	//http.HandleFunc("/headers", headerDump)
	//http.HandleFunc("/callapi-2", headerDumpCallApi2)
	//http.HandleFunc("/callapi-3", headerDumpCallApi3)

	fs := http.FileServer(http.Dir("./static"))
	http.Handle("/", fs)

	http.HandleFunc("/monkey", func(w http.ResponseWriter, r *http.Request) {

		tmpl := template.Must(template.ParseFiles("./templates/my-template.html"))

		data := Spec{Name: "Monkey Business", Node: os.Getenv("KUBERNETES_NODENAME")}

		tmpl.Execute(w, data)
	})

	log.Print("Listening on :8080...")
	err := http.ListenAndServe(":8080", nil)
	if err != nil {
		log.Fatal(err)
	}
}
