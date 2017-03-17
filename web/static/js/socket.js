import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: {token: window.userToken}})

socket.connect()

let channel = socket.channel("data:records", {})

channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

channel.push("request_points", {payload: {"type":"Polygon","coordinates":[[[121.04180574417114,14.645790594861621],[121.04180574417114,14.656544247655637],[121.05865001678465,14.656544247655637],[121.05865001678465,14.645790594861621],[121.04180574417114,14.645790594861621]]]}})

channel.on("respond_points", payload => {
  console.log(payload)
})
export default socket
