//= require ../lib/object.create

var HDO = HDO || {};

(function (H, D, W) {
  H.widgets = {
    counter: 0,
    baseUrl: '',

    load: function (baseUrl) {
      this.baseUrl = baseUrl;
      this.on('message', this.resize);

      H.widgets.create('representative').init();
      H.widgets.create('issue').init();
      H.widgets.create('topic').init();
      H.widgets.create('promises').init();
      H.widgets.create('party').init();
    },

    resize: function (event) {
      var data, action, height, iframes, style, i, l;

      data   = event.data.split(':');
      action = data[0];
      height = data[1];

      if (action !== 'hdo-widget-size') {
        return;
      }

      iframes = D.getElementsByTagName('iframe');

      for (i = 0, l = iframes.length; i < l; i++) {
        if (iframes[i].contentWindow === event.source) {
          style           = iframes[i].style;
          style.height    = data[1];
          style.maxHeight = data[1];

          return;
        }
      }
    },

    on: function (eventName, callback) {
      if (W.addEventListener) { // W3C DOM
        W.addEventListener(eventName, callback, false);
      } else if (W.attachEvent) { // IE DOM
        W.attachEvent('on' + eventName, callback);
      }
    },

    create: function (type) {
      var instance = Object.create(this);
      instance.type = type;
      return instance;
    },

    createWidgetFrame: function (opts) {
      var iframe = D.createElement('iframe');

      H.widgets.counter++;

      iframe.id          = "hdo-widget-" + H.widgets.counter;
      iframe.src         = opts.url;
      iframe.width       = '100%';
      iframe.frameBorder = 0;
      iframe.scrolling   = 'no';
      iframe.title       = 'holderdeord.no widget';

      return iframe;
    },

    queryParamFor: function (key, value) {
      return key + '=' + encodeURIComponent(value);
    },

    addIssueParams: function (el, url) {
      var issues, count;

      issues = el.getAttribute('data-issue-ids');
      count  = el.getAttribute('data-issue-count');

      if (issues && issues.length) {
        url += '?' + this.queryParamFor('issues', issues);
      } else if (count && count.length) {
        url += '?' + this.queryParamFor('count', count);
      }

      return url;
    },

    widgetOptionsFor: function (el) {
      var url;

      if (this.type === "issue") {
        url = H.widgets.baseUrl + "issues/" + el.getAttribute('data-issue-id') + '/widget';
      } else if (this.type === "representative") {
        url = H.widgets.baseUrl + "representatives/" + el.getAttribute('data-representative-id') + '/widget';
        url = this.addIssueParams(el, url);
      } else if (this.type === "party") {
        url = H.widgets.baseUrl + "parties/" + el.getAttribute('data-party-id') + '/widget';
        url = this.addIssueParams(el, url);
      } else if (this.type === "topic") {
        url = H.widgets.baseUrl + "widgets/topic?" + this.queryParamFor('issues', el.getAttribute('data-issues')) + '&'
                                                   + this.queryParamFor('promises', el.getAttribute('data-promises'));
      } else if (this.type === "promises") {
        url = H.widgets.baseUrl + "widgets/promises?" +
              this.queryParamFor('promises', el.getAttribute('data-promises'));
      } else {
        throw new Error('invalid HDO widget type: ' + this.type);
      }

      return { 'url': url };
    },

    init: function () {
      var nodes, elements, element, iframe, i, l;

      nodes = D.getElementsByClassName('hdo-' + this.type + '-widget');
      elements = [];

      for (i = 0, l = nodes.length; i < l; i++) {
        elements.push(nodes[i]);
      }

      for (i = 0, l = elements.length; i < l; i++) {
        element = elements[i];
        iframe = this.createWidgetFrame(this.widgetOptionsFor(element));

        element.parentNode.replaceChild(iframe, element);
      }
    }

  };
}(HDO, document, window));
