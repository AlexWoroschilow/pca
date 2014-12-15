$(function () {


    // Returns a flattened hierarchy containing all leaf nodes under the root.
    function classes(root) {
        var classes = [];

        function recurse(name, node) {
            if (node.children) {
                node.children.forEach(function (child) {
                    recurse(node.name, child);
                });
            }
            else classes.push(node);
        }

        recurse(null, root);
        return {children: classes};
    }

    /**
     * Add method to check
     * is element exists in array
     *
     */
    $.extend(Array.prototype, {

        inArray: function (element) {

            for (var i; i < this.length; i++) {
                if (this[i] == element) {
                    return true;
                }
            }

            return false;
        }
    });


    /**
     * Add method to
     * generate random strings
     */
    $.extend(String.prototype, {

        collection: [],
        random: function (length) {
            var chars = 'ABCDEFGHIJKLMNOPQRSTUVWXTZabcdefghiklmnopqrstuvwxyz'.split('');

            if (!length) {
                length = Math.floor(Math.random() * chars.length);
            }

            do {

                var str = '';
                for (var i = 0; i < length; i++) {
                    str += chars[Math.floor(Math.random() * chars.length)];
                }

            } while (this.collection.inArray(str));

            this.collection.push(str);

            return str;
        }
    });

    /**
     * Define a diagram class
     * to build a diagram using d3
     *
     * @param selector
     * @constructor
     */
    function Diagram(selector, diameter) {
        this.init(selector, diameter);
    }

    $.extend(Diagram.prototype, {

        svg: undefined,
        color: undefined,
        format: undefined,
        diameter: undefined,
        bubble: undefined,

        init: function (selector, diameter) {

            this.diameter = diameter;
            this.format = d3.format(",d");
            this.color = d3.scale.category20c();

            this.bubble = d3.layout.pack()
                .sort(null)
                .size([this.diameter, this.diameter])
                .padding(1.5);

            this.svg = d3.select(selector).append("svg")
                .attr("width", this.diameter)
                .attr("height", this.diameter)
                .attr("class", "bubble");

            this.decorate({
                step: 20
            });
        },

        decorate: function (options) {

            var grid = this.svg.append("g")
                .attr("class", "grid");


            var x11 = this.diameter / 2;
            var y11 = 0;

            var x21 = this.diameter / 2
            var y21 = this.diameter;

            var lineY = grid.append("line");
            lineY.attr("x1", x11).attr("y1", y11);
            lineY.attr("x2", x21).attr("y2", y21);
            lineY.style("stroke", "#000");
            lineY.style("stroke-width", "2");


            var labelY = grid.append("g");

            labelY.attr("class", "node")
                .attr("transform", function (d) {
                    return "translate(" + (x21 + 20) + ",20)";
                });

            labelY.append("text")
                .style("text-anchor", "middle")
                .style("font", "16px sans-serif")
                .text(function (d) {
                    return "PC2";
                });

            var x12 = 0;
            var y12 = this.diameter / 2;

            var x22 = this.diameter;
            var y22 = this.diameter / 2;

            var lineX1 = grid.append("line");
            lineX1.attr("x1", x12).attr("y1", y12);
            lineX1.attr("x2", x22).attr("y2", y22);
            lineX1.style("stroke", "#000");
            lineX1.style("stroke-width", "2");


            var labelX = grid.append("g");

            labelX.attr("class", "node")
                .attr("transform", function (d) {
                    return "translate(" + (x22 - 20) + ", " + (x21 - 10) + ")";
                });
            labelX.append("text")
                .style("text-anchor", "middle")
                .style("font", "16px sans-serif")
                .text(function (d) {
                    return "PC1";
                });


            var lines = grid.append("g")
                .attr("class", "grid-lines");

            for (var i = 20; i <= this.diameter; i = i + 20) {

                var x11 = i;
                var y11 = 0;
                var x21 = i;
                var y21 = this.diameter;

                var lineY = lines.append("line");
                lineY.attr("x1", x11).attr("y1", y11);
                lineY.attr("x2", x21).attr("y2", y21);
                lineY.style("stroke", "#c0c0c0");
                lineY.style("stroke-width", "1");

                var x12 = 0;
                var y12 = i;
                var x22 = this.diameter;
                var y22 = i;

                var lineX = lines.append("line");
                lineX.attr("x1", x12).attr("y1", y12);
                lineX.attr("x2", x22).attr("y2", y22);
                lineX.style("stroke", "#c0c0c0");
                lineX.style("stroke-width", "1");
            }
        },

        fill: function (source) {
            (function (self) {
                var svg = self.svg;
                var diameter = self.diameter;
                $.get(source, function (response) {
                    self._onResultLoaded(self, svg, response, diameter)
                });
            })(this)
        },

        /**
         * Parse response from server
         *
         * @param data
         * @private
         */
        _onResultLoaded: function (self, svg, response, diameter) {

            var children = [];
            var codegenerator = new String();
            var response = $(response);

            response.find('similarity').each(function (index, element) {
                var element = $(element);
                if (element.is('similarity')) {

                    var multiplier = diameter * 40 / 960;
                    var X = ((parseFloat(element.find('x').text()) * multiplier) + diameter / 2);
                    var Y = ((parseFloat(element.find('y').text()) * multiplier) + diameter / 2);

                    children.push({
                        "hash": codegenerator.random(10),
                        "name": element.find('pdbid').text(),
                        "X": X,
                        "Y": Y
                    });

                }
            });

            var labels = svg.append("g")
                .attr("class", "grid-labels")
                .selectAll(".label")
                .data(self.bubble.nodes(classes({"children": children}))
                    .filter(function (d) {
                        if (typeof(d.name) != "undefined") {
                            return d.name.length > 0;
                        }
                        return false;
                    }))
                .enter()
                .append("g")
                .attr("class", "label");

            this._decorateLabels(labels);
            this._activateLabels(labels);


            var nodes = svg.append("g")
                .attr("class", "grid-nodes")
                .selectAll(".node")
                .data(self.bubble.nodes(classes({"children": children}))
                    .filter(function (d) {
                        if (typeof(d.name) != "undefined") {
                            return d.name.length > 0;
                        }
                        return false;
                    }))
                .enter()
                .append("g")
                .attr("class", "node");

            this._decorateNodes(nodes);
            this._activateNodes(nodes);
        },

        /**
         * Decorate node elements
         *
         * @param elements
         * @private
         */
        _decorateNodes: function (elements) {

            var self = this;

            elements.attr("id", function (d) {
                return d.hash;
            });
            elements.attr("transform", function (d) {
                return "translate(" + d.X + "," + d.Y + ")";
            })

            var titles = elements.append("title");
            titles.text(function (d) {
                return d.name;
            });

            var rectangles = elements.append("rect");
            rectangles.attr("x", "-5");
            rectangles.attr("y", "-5");
            rectangles.attr("width", 10);
            rectangles.attr("height", 10);
            rectangles.style("fill", function (d) {
                return self.color(d.name);
            });

            var texts = elements.append("text");
            texts.attr("dx", ".1em");
            texts.attr("dy", "1em");
            texts.style("text-anchor", "middle");
            texts.text(function (d) {
                return d.name;
            });
        },


        /**
         * Attach actions to node
         *
         * @param elements
         * @private
         */
        _activateNodes: function (elements) {

            (function (self) {

                elements.on("click", function (node) {
                    var element = d3.select(this);
                    self.onNodeClick(self, element, node);
                });

                elements.on("mouseover", function (node) {
                    var element = d3.select(this);
                    self.onNodeMouseOver(self, element, node);
                });

                elements.on("mouseout", function (node) {
                    var element = d3.select(this);
                    self.onNodeMouseOut(self, element, node);
                });

            })(this);
        },

        /**
         * Process click event
         * use jquery
         *
         * @param self
         * @param element
         * @param node
         */
        onNodeClick: function (self, element, node) {

            var container = $(document);

            container.trigger({
                type: "click-node",
                node: node
            });
        },

        /**
         * Process node mouse over action
         *
         * @param self
         * @param node
         */
        onNodeMouseOver: function (self, element, d) {

            var text = element.select('text');
            text.attr("style", "font-size: 16px");

            var rectangle = element.select('rect');
            rectangle.attr("width", 40);
            rectangle.attr("height", 40);
            rectangle.attr("x", "-20");
            rectangle.attr("y", "-20");

            if (d3.event.generated) {

                var selector = element.append("g")
                    .attr("class", "selector");

                var colorStroke = "#0099FF";

                selector.append("line")
                    .attr("x1", d3.event.screenX)
                    .attr("x2", d3.event.screenX)
                    .attr("y1", d3.event.screenY - 100)
                    .attr("y2", d3.event.screenY + 100)
                    .style("stroke", colorStroke)
                    .style("stroke-width", "1");

                selector.append("line")
                    .attr("x1", d3.event.screenX - 100)
                    .attr("x2", d3.event.screenX + 100)
                    .attr("y1", d3.event.screenY)
                    .attr("y2", d3.event.screenY)
                    .style("stroke", colorStroke)
                    .style("stroke-width", "1");

                selector.append("rect")
                    .attr("x", d3.event.screenX - 5)
                    .attr("y", d3.event.screenY - 5)
                    .attr("width", 10)
                    .attr("height", 10)
                    .style("stroke", colorStroke)
                    .style("stroke-width", "1")
                    .style("fill", "rgba(0,0,0,0)");

                selector.append("rect")
                    .attr("x", d3.event.screenX - 15)
                    .attr("y", d3.event.screenY - 15)
                    .attr("width", 30)
                    .attr("height", 30)
                    .style("stroke", colorStroke)
                    .style("stroke-width", "1")
                    .style("fill", "rgba(0,0,0,0)");

                selector.append("rect")
                    .attr("x", d3.event.screenX - 35)
                    .attr("y", d3.event.screenY - 35)
                    .attr("width", 70)
                    .attr("height", 70)
                    .style("stroke", colorStroke)
                    .style("stroke-width", "1")
                    .style("fill", "rgba(0,0,0,0)");


                return;
            }

            var event = document.createEvent('MouseEvents');
            event.initMouseEvent("mouseover", true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null);
            event.generated = true;

            var node = d3.select("#label_" + d.hash);
            if (typeof (node.node) == "function") {
                node.node().dispatchEvent(event);
            }
        },

        /**
         * Process node mouse out action
         *
         * @param self
         * @param node
         */
        onNodeMouseOut: function (self, element, d) {

            var text = element.select('text');
            text.attr("style", "font-size: 10px");

            var rectangle = element.select('rect');
            rectangle.attr("width", 10);
            rectangle.attr("height", 10);
            rectangle.attr("x", "-5");
            rectangle.attr("y", "-5");

            if (d3.event.generated) {

                var selector = element.select('.selector');
                selector.remove();

                return;
            }

            var event = document.createEvent('MouseEvents');
            event.initMouseEvent("mouseout", true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null);
            event.generated = true;


            var node = d3.select("#label_" + d.hash);
            if (typeof (node.node) == "function") {
                node.node().dispatchEvent(event);
            }
        },

        /**
         * Decorate element labels
         *
         * @param elements
         * @private
         */
        _decorateLabels: function (elements) {

            var i = 1;
            var j = 1;
            var self = this;

            elements.attr("id", function (d) {
                return "label_" + d.hash;
            });

            elements.attr("transform", function (d) {
                var y = i++ * 15;
                var x = self.diameter - (60 * j);
                if (y > (self.diameter / 2.3)) {
                    i = 1;
                    j++;
                }
                return "translate(" + x + "," + y + ")";
            });

            var titles = elements.append("title");
            titles.text(function (d) {
                return d.name;
            });

            var rectangles = elements.append("rect");
            rectangles.attr("width", 10)
            rectangles.attr("height", 10)
            rectangles.style("fill", function (d) {
                return self.color(d.name);
            });

            var texts = elements.append("text");
            texts.attr("dx", "30px");
            texts.attr("dy", "1em");
            texts.style("text-anchor", "middle");
            texts.text(function (d) {
                return d.name;
            });
        },

        /**
         * Attach events to labels
         *
         * @param elements
         * @private
         */
        _activateLabels: function (elements) {

            (function (self) {

                elements.on("click", function (node) {
                    var element = d3.select(this);
                    self.onLabelClick(self, element, node);
                });

                elements.on("mouseover", function (node) {
                    var element = d3.select(this);
                    self.onLabelMouseOver(self, element, node);
                });

                elements.on("mouseout", function (node) {
                    var element = d3.select(this);
                    self.onLabelMouseOut(self, element, node);
                });

            })(this);

        },

        /**
         * Catch event on click label
         *
         * @param self
         * @param element
         * @param node
         */
        onLabelClick: function (self, element, node) {

            var container = $(document);
            container.trigger({
                type: "click-label",
                node: node
            });
        },

        /**
         * Proces label mouse over event
         *
         * @param self
         * @param element
         * @param node
         */
        onLabelMouseOver: function (self, element, d) {
            var rectangle = element.select('rect');
            rectangle.attr("width", 50);

            if (d3.event.generated) {
                return;
            }

            var event = document.createEvent('MouseEvents');
            event.initMouseEvent("mouseover", true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null);
            event.generated = true;

            var node = d3.select("#" + d.hash);
            if (typeof (node.node) == "function") {
                node.node().dispatchEvent(event);
            }
        },

        /**
         * Process label mouse out event
         *
         * @param self
         * @param element
         * @param node
         */
        onLabelMouseOut: function (self, element, d) {
            var rectangle = element.select('rect');
            rectangle.attr("width", 10);

            if (d3.event.generated) {
                return;
            }

            var event = document.createEvent('MouseEvents');
            event.initMouseEvent("mouseout", true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null);
            event.generated = true;

            var node = d3.select("#" + d.hash);
            if (typeof (node.node) == "function") {
                node.node().dispatchEvent(event);
            }
        }

    });


    /**
     * Jquery-Plugin method to
     * display a diagram
     *
     * @param source
     * @param diameter
     * @returns {Diagram}
     */
    $.fn.diagram = function (source, diameter) {

        var diagram = new Diagram($(this).selector, diameter);
        diagram.fill(source);
        return diagram;
    }
});