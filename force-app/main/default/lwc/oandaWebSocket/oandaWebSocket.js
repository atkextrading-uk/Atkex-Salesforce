import { LightningElement } from 'lwc';
import startStream from '@salesforce/apex/OandaStreamingAPI.startStream';
import cometdLWC from '@salesforce/resourceUrl/cometd3';
import jQuery from '@salesforce/resourceUrl/jQuery';
import cometdReloadExt from '@salesforce/resourceUrl/cometd_reloadextension';
import jQueryCometd from '@salesforce/resourceUrl/jquery_cometd';
import jQueryCometdReload from '@salesforce/resourceUrl/jquery_cometdreload';
import { loadScript } from 'lightning/platformResourceLoader';


export default class OandaWebSocket extends LightningElement {

    socket;
    token = 'd2370f84cb9b58715eaf8cba784f0dea-9326744117bf14b9100a09a677795a36';
    accountId = '001-004-6038873-002';

    connectedCallback() {
        
    }

    initCometD() {
        // Create a new CometD client
        console.log("BBBB");
        console.log($);
        //console.log(cometd);
        var cometd = new window.org.cometd.CometD();
        //console.log(cometd);

        // Configure the client to use long polling
        cometd.websocketEnabled = true;
        //cometd.websocketEnabled = false; // Disable WebSocket to use the diagnostic extension
        //cometd.registerExtension('graphdiagnostic', new org.cometd.DiagnosticExtension());

        // Set up the authentication headers
        //var url = 'https://stream-fxtrade.oanda.com/v3/accounts/001-004-6038873-001/transactions/stream'https://api-fxtrade.oanda.com
        var url = 'apex/ProxyServer/makeRequest?url=' + encodeURIComponent('https://stream-fxtrade.oanda.com/v3/accounts/001-004-6038873-004/transactions/stream');
        var url = 'https://stream-fxtrade.oanda.com/v3/accounts/001-004-6038873-004/transactions/stream';
        console.log("CCCC");
        cometd.configure({
            url: url,
            requestHeaders: {
                'Authorization' : 'Bearer ad066bf167934d6e651cb1062f8e3c54-61359152af15b810bcbaf587afb8c0d6',
                'Content-Type' : 'application/json',
                'Access-Control-Allow-Credentials' : 'true'
                // 'Access-Control-Allow-Origin' : 'true'
            }
        });
        // Connect to the CometD server
        cometd.handshake(response => {
            console.log("DDDD");
            console.log(response);
            if (response.successful) {
                console.log("EEEE");
                // Subscribe to the stream
                cometd.subscribe('/v3/accounts/001-004-6038873-004/transactions/stream', message => {
                    // Handle the streaming data
                    console.log(message);
                });
            } else {
                console.log("FFFF");
                console.error('CometD handshake failed:', response);
            }
        });
    }

    startWebsocket() {
        console.log("start websocket");
        // Load the CometD library
        console.log("AAAA");
        Promise.all([
            // Load the jQuery library (required by CometD)
            loadScript(this, jQuery).then(() => console.log('jQuery loaded')).then(() => console.log($)),
            //loadScript(this, cometdReloadExt).then(() => console.log('cometdReloadExt loaded')),
            // Load the CometD library
            
            loadScript(this, cometdLWC + '/js/cometd/cometd.js').then(() => console.log('CometD loaded')),
            loadScript(this, cometdLWC + '/js/cometd/ReloadExtension.js').then(() => console.log('CometD RE loaded')),

            loadScript(this, jQueryCometd).then(() => console.log('jQueryCometd loaded'))
            //loadScript(this, jQueryCometdReload).then(() => console.log('jQueryCometdReload loaded'))
        ]).then(() => {
            // Initialize the CometD client and subscribe to the stream
            //const cometdObj = new CometD();
            
            //-----------------Line here to stop comet d
            this.initCometD();
        }).catch(error => {
            console.error('Error loading:', error);
        });



        /*const token = 'c9fcb2972913d5f84bb8225af2824cea-a468fc42bec599398303967753094267';

        // create a new WebSocket object
        this.socket = new WebSocket('wss://stream-fxtrade.oanda.com/v3/accounts/001-004-6038873-002/transactions/stream', {
            headers: {
                Authorization: `Bearer ${token}`
            }
        });

        // handle WebSocket connection events
        this.socket.addEventListener('open', event => {
            console.log('WebSocket connection opened');
        });

        this.socket.addEventListener('close', event => {
            console.log('WebSocket connection closed');
        });

        this.socket.addEventListener('error', event => {
            console.error('WebSocket error:', event);
        });

        // handle incoming WebSocket messages
        this.socket.addEventListener('message', event => {
            console.log('WebSocket message received:', event.data);
            // do something with the message data here
        });

        //console.log("button called");
        //const socket = new WebSocket('https://api-fxtrade.oanda.com/v3/accounts/001-004-6038873-001/trades/ws');
        /*const socket = new WebSocket('wss://stream-fxtrade.oanda.com/v3/accounts/001-004-6038873-001/transactions/stream');
        socket.onopen = function() {
            console.log('WebSocket connected to Oanda Streaming API');
            // Subscribe to the PushTopic you created in Salesforce
            socket.send(JSON.stringify({ "type": "subscribe", "topic": "/topic/Oanda_Trade_Stream" }));
        }
        socket.onmessage = function(event) {
        console.log('Received trade event from Oanda Streaming API:', event.data);
        // Send the trade event to Salesforce via a POST request
        const xhr = new XMLHttpRequest();
        xhr.open('POST', '/services/data/v49.0/sobjects/TradeEvents__e/');
        xhr.setRequestHeader('Authorization', 'Bearer 63375670e994e2795814162b77857737-964243e148eb19c344c5753896168050');
        xhr.setRequestHeader('Content-Type', 'application/json');
        xhr.send(JSON.stringify({ "Data__c": event.data }));
        }
        console.log("button called");
        startStream().then(response => {
            console.log("response");
        });*/
        
    }
    stopWebsocket() {
        console.log("stop websocket");
        //this.socket.close();
    }
}