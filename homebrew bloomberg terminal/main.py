import matplotlib
matplotlib.use('Agg')
from matplotlib import pyplot as plt
import numpy as np
from flask import Flask, render_template, request, jsonify, session, url_for
import json

App = Flask(__name__)
@App.route("/", methods=["POST", "GET"])
def home():
    try:
        for i in request.form.keys():
            LOS = i.split("|")
            for n in range(0, 2):
                Chart = LOS[n]
                C = ""

                for z in Chart:
                    if not z == '\x00':
                        C += z
            
                Chart = Chart.split(",")

                Match = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ' ', '.', ':']
                AddInfo = ''.join([s for s in Chart[-1] if s in Match])
                AddInfo += Chart[-2]
                XAxis = [z for z in range(0, 120)]
                YAxis = [float(Chart[z]) for z in XAxis]
                plt.figure()
                
                if n == 0:
                    plt.plot(XAxis, YAxis, color='green', label='Live')
                    plt.legend()
                    plt.savefig('static/img/livechart.png')
                if n == 1:
                    plt.plot(XAxis, YAxis, label=AddInfo)
                    plt.legend()
                    plt.savefig('static/img/datasetchart.png')
                plt.cla()
                plt.close('all')
    except Exception as e:
        print(e)
    return render_template('index.html')
if __name__ == "__main__":
    #192.168.0.118
    #443 for https 80 for http
    # context = ('sircoin.org_ssl_certificate.cer', '_.sircoin.org_private_key.key')
    App.run(debug=True, host='localhost', port=80)
