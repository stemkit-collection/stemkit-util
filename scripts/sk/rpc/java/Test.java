
import java.net.*;
import java.util.*;

import org.apache.xmlrpc.client.*;
import org.apache.xmlrpc.*;

class Communicator {

  Communicator(String endpoint) throws MalformedURLException {
    XmlRpcClientConfigImpl config = new XmlRpcClientConfigImpl();
    config.setServerURL(new URL(endpoint));
    _client = new XmlRpcClient();
    _client.setConfig(config);
  }

  void connect(String host, Integer port, String user, String password) throws XmlRpcException {
    Vector<Object> params = new Vector<Object>();

    params.addElement(host);
    params.addElement(port);
    params.addElement(user);
    params.addElement(password);

    _handle = (Integer)_client.execute("Connect", params);
    System.out.println(">>> handle=" + _handle);
  }

  String version() throws XmlRpcException {
    Vector<Object> params = new Vector<Object>();

    params.addElement(_handle);

    String version = (String)_client.execute("Version", params);
    System.out.println(">>> version=" + version);

    return version;
  }

  void captureInfo() throws XmlRpcException {
    Vector<Object> params = new Vector<Object>();

    params.addElement(_handle);

    HashMap info = (HashMap)((Object[])_client.execute("CaptureInfo", params))[0];
    System.out.println(">>> capture=" + info);
  }

  void configs() throws XmlRpcException {
    Vector<Object> params = new Vector<Object>();

    params.addElement(_handle);

    Object[] info = (Object[])_client.execute("Configs", params);
    for(int index=0; index < info.length ;index++) {
      System.out.println(">>> config=" + info[index]);
    }
  }

  private Integer _handle;
  private XmlRpcClient _client;
}

public final class Test {
  public static void main(String[] argv) throws MalformedURLException, XmlRpcException {
    Communicator communicator = new Communicator("http://localhost:3000/observation/api");

    communicator.connect("irvspxl08.quest.com", 8568, "qarun", "qarun");
    communicator.version();
    communicator.captureInfo();
    communicator.configs();
  }
}
