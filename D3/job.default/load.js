$(".result_header").ready(function(){
        $(".result_header").load("../../job.default/header.html", function(){
                                        $("#menu").menu();
					load_results();
                                });
});



function load_results(){

	$("#result_box").ready(function(){
		var loc = window.location.pathname.split("/");
		var xml_path = "../jobs/" + loc[loc.length-2] + "/results.xml";
        	jQuery.ajax({
                	type: "POST",
	                url: '../../job.default/xslt.php',
			data: {xml: xml_path, xsl: 'results.xsl'},
                	success:function(data) {
                        	var converted = data.split("**/?**");
	                        $("#results_box").html(converted[0]);
        	                // Params 1) structure 2) title 3) rmsd_thresh 4) min_f_dme 5) max_n 6) jobfolder 7) add_to_calc
                	        window.query_structure = converted[1].replace("\n", "").replace("\t", "").replace(" ", "");
                        	$(".span_query_structure").ready(function(){
					$(".span_query_structure").html(window.query_structure);
				});
				$("span#rmsd_thresh").html(converted[3]);
                	        $("span#min_fdme").html(converted[4]);
                        	$("span#max_n").html(converted[5]);
	                        var dataTable = $("#results").dataTable({ "aaSorting": [[ 2, "desc" ]], 
									  "dom": 'ftpl',
									});
                        	$("table#results").find("tr.hit:first").addClass("selected");
  
	                        // Hide cols an checkboxes
        	                var hideCols =[1,3,5];
                	        for (var i=1; i<8; i++){
                        	        if ($.inArray(i, hideCols) != -1){
                                	        dataTable.fnSetColumnVis(i, false);
	                                } else {
        	                                $(".col_check#"+i).attr("checked", "true");
                	                }
                        	}

	                        // handler: Checkboxes for displaying columns
        	                $('.col_check').click(function(){
                	                var id = $(this).attr('id');
                        	        if ($(this).is(":checked")){
                                	        dataTable.fnSetColumnVis(id, true);
	                                } else {
        	                                dataTable.fnSetColumnVis(id, false);
                	                }
                        	});
	                        $(document).delegate("tr.hit", "click", click_row);
				//$(document).delegate("tr.hit", "click", alert_mouse_pos);
                	}

	        });
	});

}

function load_first_hit(){
        $("#results").ready(function(){
		var jmolSize =[Math.round($("#jmolBox").width()), Math.round($("#jmolBox").height()-80)];
            	jmolResizeApplet(jmolSize);
                
		var first = $("table#results").find(".hit:first").find("td:first").html();
                update_links(first);
                load_jmol_ids([first, window.query_structure]);
        });
}

function load_jmol_ids(ids){
        var jmolLoad = 'load FILES';
        for (var i=0; i<ids.length; i++){
                jmolLoad += ' "modeldir/' + ids[i] + '.pdb" ';
        }
        jmolLoad += "; hbonds off; wireframe off; spacefill off; trace off; slab off; ribbons off; label off; monitor off; cartoon; model 0; select 1.1; color [120,230,120]; select 2.1; color [120,120,230]";
	jmolScript(jmolLoad);
}

function click_row(){
        var rows = $("table#results").find("tr.hit");
        var new_pdb = $(this).find("td:first").html();
        var old_pdb = $("table#results").find(".selected").find("td:first").html();
	
	window.cursor_x = $(this).position().left + 30;
	window.cursor_y = $(this).position().top - document.body.scrollTop + 12;
        make_details(new_pdb, old_pdb);
        rows.removeClass("selected");
        $(this).addClass("selected");
}



function update_links(new_pdb){
        var arr = window.location.pathname.split("/");
        var jobfolder = arr[arr.length-2];
        $("#fastalink").attr("href", "../../job.default/download_alignment.php?alignment="+new_pdb+"&jobfolder="+jobfolder);
        $("#pdblink").attr("href", "modeldir/"+ new_pdb +".pdb");
        $("#pdbpagelink").attr("href", "http://www.rcsb.org/pdb/explore/explore.do?structureId="+new_pdb.substr(0, new_pdb.length-1) +"&width=90%&height=90%;");
}

function make_details(pdb_id, old_pdb){

        var alignment;
        var path = 'json/'+pdb_id+'.json';
        $.get(path, function(data){
                alignment = $.parseJSON(data);

        var plot_data = new Array();
        var seq_cons_plot = new Array();

        var details = "";
        var l = alignment.conservation.length ;
        var linesize = 50;
        var real_position = [];

        for(var chain_id in alignment.chains){
                var positions = [];
                var pos_index = 0;
                for (var i=0; i<l; i++){
                        if (alignment.chains[chain_id][i] == "-"){
                                positions.push(-1);
                        } else {
                                positions.push(alignment[chain_id+"_positions"][pos_index]);
                                pos_index ++;
                        }
                }
                real_position.push(positions);
        }

        /* walk through the alignment from left to right */
        for(var row=0; l-row*linesize>0; row++){
                for (var i=row*linesize; i<l && i< (row+1)*linesize; i++){
                        seq_cons_plot.push(alignment.seq_conservation[i]);
                        plot_data.push(alignment.conservation[i]);
                }
                details += '<span class="seq_conservationGraph" title="sequence conservation">'+seq_cons_plot+'</span><br/>';//join()??
                details += '<span class="conservationGraph" title="structure conservation">'+plot_data+'</span><br/>';
                var model_nr = 1;
                for(var chain_id in alignment.chains){
                        details += '<span class="start_line">';
                        details += chain_id+" </span>";
                        for (var i=row*linesize; i<l && i< (row+1)*linesize; i++){
                                var position_id = real_position[model_nr-1][i] + "/" + model_nr + ".1";
                                details += make_character(alignment.chains[chain_id][i], chain_id, position_id, alignment.conservation[i], alignment.used[i]);
                        }
                        details += '<span class="alignmentEnd"></span>\n';
                        details +='<br/>';
                        model_nr ++;
                }
                details += '<br/>';
                seq_cons_plot = new Array();
                plot_data = new Array();
        }
	details += "<div id='related_pdbs'></div>";

	$("#alignment_details").html(details);
	generate_related_pdbs(pdb_id);

	$( "span.alignment" ).on( "mouseenter", function() {
        	highlight_Jmol($(this).attr("id"), 1);
	}).on( "mouseleave", function() {
        	highlight_Jmol($(this).attr("id"), -1);
	});
        
	// display dialog eventually
	if (pdb_id == old_pdb){
		var x = window.cursor_x;
		var y = window.cursor_y;
                $("#alignment_details").dialog({
			create: function(e,ui) {  $(this).dialog('widget').find('.ui-dialog-titlebar').removeClass('ui-corner-all')},
                                title: "Alignment of " + window.query_structure + " and " + pdb_id,
				position:  [x+50, y+15],
                            	resizable: false,
                            	draggable: true
                });
        	$('.seq_conservationGraph').sparkline('html',{type:'bar',chartRangeMax:1 ,barColor:  '#bfafff', barWidth:8, barSpacing:2});
        	$('.conservationGraph').sparkline('html',{type:'bar',chartRangeMax:1 ,barColor: '#ff00ff', barWidth:8, barSpacing:2});
        } else {
		$("#alignment_details").dialog("close");
                load_jmol_ids([pdb_id, window.query_structure]);
                update_links(pdb_id);
        }

        }); // parseJSON
}

function generate_related_pdbs(pdb_id){
    $.get("../../job.default/related_pdbs/get_related_pdb.php", { chain: pdb_id }, function(data){
	var ids = data.split(" ");
        var str = "";
        for(var i in ids){
            var id=ids[i].substr(0,ids[i].length-1);
            str+=' <a target="_blank" href="http://www.rcsb.org/pdb/explore/explore.do?structureId='+id+'&width=90%&height=90%;">'+ids[i]+'</a>';
        }
	$("#related_pdbs").ready(function(){
		$("#related_pdbs").html(str);
	});
    });
}

function make_character(c, chain_id, position_id, conservation, used){
        var character;
        if(c == "-"){
                character = '<span class="gap" ';
        } else {
                character = '<span id="' + position_id + '" ';
                if(used == "1"){
                        character += 'class="used4sup alignment" ';
                } else {
                        character += 'class="alignment" ';
                }
        }
        character += ' title="structure conservation: ' + conservation + '">' + c + '</span>';
        return character;
}

// color == -1 for uncolor, color == 1 for default color
function highlight_Jmol(position, color){
        if (color != -1){
                if(color==1){
                        if (position.indexOf("/1.1") > -1){
                                color="green";
                        } else {
                                color="blue";
                        }
                }
                jmolScript("select " + position + "; halos 200; color halos "+color+";");
        } else {
                jmolScript("select " + position + "; halos 0;");
        }

}


