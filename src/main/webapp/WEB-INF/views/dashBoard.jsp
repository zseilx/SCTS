<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<script src="resources/customjs/sockjs.js"></script>
<script src="resources/customjs/drawingTile.js"></script>
<script src="resources/customjs/dashBoard.js"></script>
<script src="resources/customjs/productRelocation.js"></script>
<link href="resources/customcss/tileMapClick.css" rel="stylesheet" />
<script src="resources/customjs/numberComma.js"></script>


<style>
#tile_info_avgTime {
	display: none;
}

#selectTile {
	display: none;
}

#tile_info>span {
	display: none
}
</style>

<script>
	var chart;
	var DashDaysock = new SockJS("/scts/echo-ws");
	var bhf_code = "${bhf_code}";

	DashDaysock.onopen = function() {
		console.log('open');
		sendMessage();
	};

	DashDaysock.onmessage = function(event) {
		daySales(event.data);
	};

	function sendMessage() {

		var json = JSON.stringify({
			bhf_code : bhf_code
		});

		DashDaysock.send(json);
	}

	var realTimeSock = new SockJS("/scts/realtime-ws");

	realTimeSock.onopen = function() {

		realTimeSend();
		setInterval(realTimeSend, 1000);
	}

	function realTimeSend() {

		var json = JSON.stringify({
			bhf_code : bhf_code
		});

		realTimeSock.send(json);
	}

	var todayCount;

	realTimeSock.onmessage = function(event) {
		var e_data = event.data;
		e_data = JSON.parse(e_data);

		$("#todayVisitor .count").text(
				thousandSeparatorCommas(e_data.todayCount));
		$("#todaySales .count")
				.text(thousandSeparatorCommas(e_data.todaySales));
		$("#monthAvgVisitor .count").text(
				thousandSeparatorCommas(e_data.monthAvgVisitor));
		$("#monthTotalSales .count").text(
				thousandSeparatorCommas(e_data.monthTotalSales));

		todayCount = e_data.todayCount - e_data.realVisitor2;
		
		if(todayCount < 0){
			todayCount = 0;
		}

	}

	var daySales = function(data) {

		data = JSON.parse(data);

		var length = data.result.length;

		if (length <= 0) {
			$("#dayday").text("일주일 간의 매출이 존재하지 않습니다.").css("line-height",
					"400px");

		} else {

			var options = {

				title : {
					text : '일매출'
				},
				subtitle : {
					text : 'Plain'
				},
				xAxis : {
					categories : []
				},
				series : [ {
					type : 'column',
					colorByPoint : true,
					data : [],
					showInLegend : false
				} ]

			}

			for (var i = 0; i < length; i++) {

				options.xAxis.categories[i] = data.result[i].bill_issu_de;
				options.series[0].data[i] = parseInt(data.result[i].totalPrice);

			}

			chart = Highcharts.chart('barChart', options);

		}

	}

	var i = -1;
	$(document).ready(
			function() {

				productImgLoad(0);

				highchartTheme();

				Highcharts.setOptions({
					global : {
						useUTC : false
					},
					lang : {

						numericSymbols : null,

					}
				});

				

				var options = {
					chart : {
						type : 'spline',
						animation : Highcharts.svg, // don't animate in old IE
						marginRight : 10,
						events : {
							load : function() {

								// set up the updating of the chart each second
								var series = this.series[0];
								setInterval(function() {
									var x = (new Date()).getTime(), // current time
									y = todayCount;
									series.addPoint([ x, y ], true, true);
								}, 1000);
							}
						}
					},
					title : {
						text : '현재 매장 안의 방문자'
					},
					xAxis : {
						type : 'datetime',
						tickPixelInterval : 150
					},
					yAxis : {
						title : {
							text : 'Value'
						},
						plotLines : [ {
							value : 0,
							width : 1,
							color : '#808080'
						} ],
						tickInterval: 1
					},
					tooltip : {
						formatter : function() {
							return '<b>'
									+ this.series.name
									+ '</b><br/>'
									+ Highcharts.dateFormat(
											'%Y-%m-%d %H:%M:%S', this.x)
									+ '<br/>'
									+ Highcharts.numberFormat(this.y, 2);
						}
					},
					legend : {
						enabled : false
					},
					exporting : {
						enabled : false
					},
					series : [ {
						name : '현재 매장 방문자',
						data : (function() {
							// generate an array of random data
							var data = [], time = (new Date()).getTime(), i;

							for (i = -19; i <= 0; i += 1) {
								data.push({
									x : time + i * 1000,
									y : todayCount
								});
							}
							return data;
						}())
					} ]
				}

				Highcharts.chart('charts', options);

				$('#plain').click(function() {
					chart.update({
						chart : {
							inverted : false,
							polar : false
						},
						subtitle : {
							text : 'Plain'
						}
					});
				});

				$('#polar').click(function() {

					chart.update({
						chart : {
							inverted : false,
							polar : true
						},
						subtitle : {
							text : 'Polar'
						}
					});
				});

				$('#inverted').click(function() {
					chart.update({
						chart : {
							inverted : true,
							polar : false
						},
						subtitle : {
							text : 'Inverted'
						}
					});
				});

				goods_locationTile();

			});
</script>
<!-- 이 부분은 일매출, 일 방문자 수 등 보임!!!!!!!!!! -->
<div class="row">
	<div class="col-lg-3 col-md-3 col-sm-12 col-xs-12" id="todayVisitor">
		<div class="info-box blue-bg">
			<i class="fa fa-cloud-download"></i>
			<div class="count">0</div>
			<div class="title">오늘 방문자</div>
		</div>
		<!--/.info-box-->
	</div>
	<!--/.col-->

	<div class="col-lg-3 col-md-3 col-sm-12 col-xs-12" id="todaySales">
		<div class="info-box orange-bg2">
			<i class="fa fa-shopping-cart"></i>
			<div class="count">0</div>
			<div class="title">오늘 판매량</div>
		</div>
		<!--/.info-box-->
	</div>
	<!--/.col-->

	<div class="col-lg-3 col-md-3 col-sm-12 col-xs-12" id="monthAvgVisitor">
		<div class="info-box yellow-bg2">
			<i class="fa fa-thumbs-o-up"></i>
			<div class="count">0</div>
			<div class="title">이번달 방문자</div>
		</div>
		<!--/.info-box-->
	</div>
	<!--/.col-->

	<div class="col-lg-3 col-md-3 col-sm-12 col-xs-12" id="monthTotalSales">
		<div class="info-box dark-bg">
			<i class="fa fa-cubes"></i>
			<div class="count">0</div>
			<div class="title">이번달 총 판매량</div>
		</div>
		<!--/.info-box-->
	</div>
	<!--/.col-->

</div>

<!-- 하이차트 : 매출 들어갈곳 -->
<div class="row" style="margin-top: 30px;">

	<div class="col-lg-6">
		<section class="panel">
			<header class="panel-heading chartTitle"> 일매출 </header>
			<div class="panel-body text-center" id="dayday">
				<div id="barChart" style="width: 100%; height: 400px"></div>
				<button id="plain" class="btn btn-default">Plain</button>
				<button id="inverted" class="btn btn-default">Inverted</button>
				<button id="polar" class="btn btn-default">Polar</button>
			</div>
		</section>
	</div>

	<div class="col-lg-6">
		<section class="panel">
			<header class="panel-heading chartTitle"> 실시간 방문자수 </header>
			<div class="panel-body text-center" style="height:466px;">
				<div id="charts"></div>
			</div>
		</section>

	</div>


</div>

<!-- 대시보드 -->
<div class="row" style="height: 500px;">
	<div style="margin-left: 15px; width: 800px; float: left;">
		<div class="panel panel-default">
			<div class="panel-heading">
				<h2>
					<i class="fa fa-map-marker red"></i><strong>매장구조</strong>
				</h2>
				<div class="panel-actions">

					<a href="#" class="btn-setting" id="leftDrawingBtns"><i
						id="leftBtns" class="fa fa-chevron-left" aria-hidden="true"></i></a> <a
						href="#" class="btn-setting" id="rightDrawingBtns"><i
						id="rightBtns" class="fa fa-chevron-right" aria-hidden="true"></i></a>
				</div>
			</div>
			<div class="panel-body-map">
				<input type="hidden" id="tileShowType" value="2"> <input
					type="hidden" id="countStory" value="${ countStory }"> <input
					type="hidden" id="floor" value="0"> <input type="hidden"
					id="drw_code" value="0">
				<div id="blueprint"
					style="height: 380px; text-align: center; position: absolute; z-index: 1;">

				</div>


				<!-- 전체 타일 영역 잡을 것. 위에 이미지 태그와 겹칠수 있도록 정의해야함 -->
				<div class="tileMap"
					style="position: absolute; width: 800px; height: 380px; z-index: 2;">
					<!-- 타일영역 전체 감싸는 div -->
				</div>
				<!-- 타일영역 전체 감싸는 div -->

			</div>

		</div>
	</div>

	<div class="col-md-3"
		style="background-color: white; width: 350px; height: 417px; position: absolute; left: 59%; border: 1px solid #D5D5D5; text-align: center;">
		<div id="loadTile">
			<div style="margin-bottom: 30px; margin-top: 10px">
				<button class="btn btn-default" id="gender">성별</button>
				<button class="btn btn-default" id="age">연령별</button>
				<button class="btn btn-default" id="visitor" disabled>방문자수</button>
				<select id="duration">
					<option value="0">1일</option>
					<option value="7">1주일</option>
					<option value="30" selected>한달</option>
				</select>
			</div>
		</div>

		<div id="selectTile">
			<div style="margin-bottom: 30px; margin-top: 10px">
				<button class="btn btn-default" id="tileGender">성별</button>
				<button class="btn btn-default" id="tileAge">연령별</button>
				<button class="btn btn-default" id="tileVisitor">방문자수</button>
				<select id="tileDuration">
					<option value="0">1일</option>
					<option value="7" selected>1주일</option>
					<option value="30">한달</option>
				</select>
			</div>

		</div>

		<div id="tile_info">
			<div id="tile_info_avgTime">
				존 평균 머문 시간 : <span id="avgTime"></span>
			</div>
			<span id="drw_code1"></span> <span id="X_index"></span> <span
				id="Y_index"></span>
		</div>

		<div style="margin-bottom: 20px">
			<span id="tileName">전체</span> <span id="title" data-id="1">성별</span>
			방문율
		</div>

		<div id="tile_graph"
			style="min-width: 300px; height: 200px; max-width: 300px; margin: 0 auto; float: left; border: 1px solid black"></div>


	</div>
	<div
		style="overflow-y: auto;position: absolute; left: 53%; stext-align: center;">
		<button class="btn btn-default" id="zoneType">고객</button>
		<!-- <button class="btn btn-default" id="categoryType">카테고리 별</button> -->
		<button class="btn btn-default" id="demoType">VIP</button>
	</div>
	<div
		style="overflow-y: auto; margin-top: 40px; width: 100px; height: 380px; position: absolute; left: 53%; border: 1px solid #D5D5D5; text-align: center;">

		<div style="height: 35px; font-size: 18px;">단위 - %</div>
		<div
			style="height: 38px; background: rgba(250, 236, 197, 1); font-size: 18px;">0
			- 2</div>
		<div
			style="height: 38px; background: rgba(255, 228, 0, 1); font-size: 18px;">3
			- 5</div>
		<div
			style="height: 38px; background: rgba(255, 167, 167, 1); font-size: 18px; color: white">6
			- 8</div>
		
		<div
			style="height: 38px; background: rgba(255, 94, 0, 1); font-size: 18px; color: white">
			 9</div>
		
		<div
			style="height: 38px; background: rgba(152, 0, 0, 1); font-size: 18px; color: white">10</div>
		<div
			style="height: 38px; background: rgba(171, 242, 0, 1); font-size: 18px;">11
			- 15</div>
		<div
			style="height: 38px; background: rgba(34, 116, 28, 1); font-size: 18px; color: white">16
			- 20</div>
		<div
			style="height: 38px; background:rgba(95, 0, 255, 1); font-size: 18px; color: white">21
			- 25</div>
		<div
			style="height: 38px; background: rgba(0, 34, 102, 1); font-size: 18px; color: white">25이상
		</div>
	
	</div>

	<div
		style="background-color: white; overflow-y: auto; width: 410px; height: 417px; position: absolute; left: 78%; border: 1px solid #D5D5D5; text-align: center;">

		<div id="goods_info">존을 클릭해주세요</div>
	</div>
</div>


<div class="row" style="height: 500px;">
	<div class="col-lg-7">
		<div class="panel panel-default">
			<div class="panel-heading">
				<h2>
					<i class="fa fa-map-marker red"></i><strong>존 별 매출 및 방문자
						평균 머문 시간</strong>
				</h2>
			</div>
			<section class="panel" style="overflow: scroll; height: 430px;">

				<table class="table table-advance">
					<thead>
						<tr>
							<th style="text-align: center;">고객 분류(나이/성별/결혼여부)</th>
							<th style="text-align: center;">방문자 평균 머문 시간(초)</th>
							<th style="text-align: center;">매출(원)</th>
						</tr>
					</thead>
					<tbody id="tile_goods">
						<tr>
							<td colspan="3">존을 클릭해주세요.</td>
						</tr>
					</tbody>
				</table>
			</section>

		</div>
	</div>
	<div
		style="background-color: white; overflow-y: auto; width: 680px; height: 450px; position: absolute; left: 63%; border: 1px solid #D5D5D5; text-align: center;">

		<div id="goods_graph" style="margin-top: 25px;">
			<h3>리스트를 클릭해주세요</h3>
		</div>

	</div>
</div>

<div id="productRelocation">
	<div class="row" style="height: 500px;">

		<div style="margin-left: 15px; width: 800px; float: left;">
			<div class="panel panel-default">
				<div class="panel-heading">
					<h2>
						<i class="fa fa-map-marker red"></i><strong>상품 재배치</strong>
					</h2>
					<div class="panel-actions">
						<a href="#" class="btn-setting leftDrawingBtns"><i
							class="fa fa-chevron-left leftBtns" aria-hidden="true"></i></a> <a
							href="#" class="btn-setting rightDrawingBtns"><i
							class="fa fa-chevron-right rightBtns" aria-hidden="true"></i></a>
					</div>
				</div>
				<div class="panel-body-map">
					<input type="hidden" class="tileShowType" value="2"> <input
						type="hidden" class="countStory" value="${ countStory }">
					<input type="hidden" class="floor" value="0"> <input
						type="hidden" class="drw_code" value="0">
					<div class="blueprint"
						style="height: 380px; text-align: center; position: absolute; z-index: 1;">
					</div>


					<!-- 전체 타일 영역 잡을 것. 위에 이미지 태그와 겹칠수 있도록 정의해야함 -->
					<div class="tileMap2"
						style="position: absolute; width: 800px; height: 380px; z-index: 2;">
						<!-- 타일영역 전체 감싸는 div -->
					</div>
					<!-- 타일영역 전체 감싸는 div -->

				</div>

			</div>
		</div>

		<div
			style="background-color: white; width: 480px; height: 417px; position: absolute; left: 53%; border: 1px solid #D5D5D5; text-align: center;">
			<h2>상품 카테고리</h2>
			<div id="category_info" style="overflow-y: auto; height: 350px;">
				<table class="table table-striped table-advance table-hover">
					<thead>
						<tr>
							<th style="text-align: center;">타일 이름</th>
							<th style="text-align: center;">카테고리 번호</th>
							<th style="text-align: center;">세부 카테고리 이름</th>
							<th style="text-align: center;">색깔</th>
						</tr>
					</thead>
					<tbody id="detail_categoryList">

					</tbody>
				</table>
			</div>
		</div>

		<div
			style="background-color: white; overflow-y: auto; width: 350px; height: 417px; position: absolute; left: 79%; border: 1px solid #D5D5D5; text-align: center;">

			<div id="tile_goodsLoList">카테고리를 클릭해주세요</div>
		</div>
	</div>



	<div class="row"
		style="margin-top: -4%; margin-right: 4%; margin-bottom: 1%;">
		<button style="float: right; background-color: #F15F5F; color: white"
			class="btn" id="relocationComplete">상품 재배치 완료</button>
	</div>
</div>




<script>
	$(document)
			.on(
					"click",
					".detailList",
					function() {
						var tile_code = $(this).attr("data-id");
						var goods_info = $("#tile_goodsLoList");

						goods_info.empty();

						goods_info.append($("<h3></h3>").text("배정된 물품"));
						goods_info
								.append($("<table class='table table-hover tileGoodsLo'></table>"));
						$(".tileGoodsLo").append(
								$("<thead class='tgGoods'></thead>"));
						$(".tgGoods").append($("<tr class='TthTr'></tr>"));
						$(".TthTr").append($("<th></th>").text("물품번호"));
						$(".TthTr").append($("<th></th>").text("물품이름"));
						$(".TthTr").append($("<th></th>").text("물품가격"));
						$(".tileGoodsLo").append(
								$("<tbody class='tile_goodsLoList'></tbody>"));

						$
								.ajax({

									url : "getGoods_locationList",
									type : "get",
									data : {
										tile_code : tile_code
									},
									dataType : "json",
									success : function(data) {
										if (data.length > 0) {
											for (var i = 0; i < data.length; i++) {
												$(".tile_goodsLoList")
														.append(
																$(
																		"<tr class='goodsLo'></tr>")
																		.attr(
																				"data-id",
																				data[i].goods_code));
												$(
														".goodsLo[data-id="
																+ data[i].goods_code
																+ "]")
														.append(
																$("<td></td>")
																		.text(
																				data[i].goods_code));
												$(
														".goodsLo[data-id="
																+ data[i].goods_code
																+ "]")
														.append(
																$("<td></td>")
																		.text(
																				data[i].goods_nm));
												$(
														".goodsLo[data-id="
																+ data[i].goods_code
																+ "]")
														.append(
																$("<td></td>")
																		.text(
																				thousandSeparatorCommas(data[i].goods_pc)));
											}

										} else {
											$(".tile_goodsLoList")
													.append(
															$("<tr></tr>")
																	.append(
																			$(
																					"<td colspan='4'></td>")
																					.text(
																							"물품이 존재하지 않습니다.")));
										}
									}

								});

						var tile = $(".tileMap2 .active");
						var detailctgry_code = parseInt($(this)
								.find("td:first").next().text());
						var detailctgry_nm = $(this).find("td:first").next()
								.next().text();
						var detailctgry_color = $(this).find(".color").find(
								"span:last").text();
						var goodsList;

						$(".tile2")
								.each(
										function() {
											if ($(this).is(
													"[data-detailctgry_code]") == true) {

												if (parseInt($(this)
														.attr(
																"data-detailctgry_code")) == detailctgry_code) {
													goodsList = $(this).attr(
															"data-goodsList");
													$(this).empty();
													$(this).css("background",
															"none");
													$(this)
															.removeAttr(
																	"data-detailctgry_code");
													$(this).removeAttr(
															"data-goodsList");

												}
											}

										});

						tile.empty();
						tile.attr("data-detailctgry_code", detailctgry_code);
						tile.attr("data-goodsList", goodsList);
						$("<span></span>").text(detailctgry_nm).appendTo(tile);
						tile.css("background-color", hexToRgbA("#"
								+ detailctgry_color, 0.1));

					});

	$("#relocationComplete")
			.click(
					function() {

						var tileArray = new Array();

						var goodsArray = new Array();

						var drw_code = parseInt($(".drw_code").val());

						$(".tile2")
								.each(
										function() {

											var totalNum = $("div.tile2")
													.index($(this));
											var RowNum = $("div.tileMap > div:first > .tile").length;

											var drw_code = $(".drw_code").val();
											var X_index = parseInt(totalNum
													/ RowNum);
											var Y_index = totalNum % RowNum;

											if ($(this).is(
													"[data-detailctgry_code]") == true) {
												var tileObj = new Object();
												var detailctgry_code = parseInt($(
														this)
														.attr(
																"data-detailctgry_code"));
												tileObj.tile_crdnt_x = X_index;
												tileObj.tile_crdnt_y = Y_index;
												tileObj.detailctgry_code = detailctgry_code;
												tileArray.push(tileObj);
												console.log(detailctgry_code);

												if ($(this).is(
														"[data-goodsList]") == true) {
													var arr;
													if ($(this).attr(
															"data-goodsList")
															.match(",")) {
														arr = $(this)
																.attr(
																		"data-goodsList")
																.split(",");

													} else {
														arr = new Array();
														arr
																.push($(this)
																		.attr(
																				"data-goodsList"));
													}
													console.log(arr);
													for (var i = 0; i < arr.length; i++) {
														var goodsObj = new Object();
														goodsObj.goods_code = parseInt(arr[i]);
														goodsObj.tile_crdnt_x = X_index;
														goodsObj.tile_crdnt_y = Y_index;
														goodsArray
																.push(goodsObj);
														console.log(goodsObj);

													}

												}

											}

										});

						var jObject = new Object();

						if (tileArray.length > 0) // 타일 없을경우 어레이는 안들어가게 만듬
							jObject.tileList = tileArray;
						jObject.drw_code = drw_code;

						var json = new Object();

						if (goodsArray.length > 0)
							json.goodsList = goodsArray;
						json.drw_code = drw_code;

						setTileCategory(jObject);
						setGoodsLocation(json);

					});

	$("div.tileMap2").on("mouseover", ".tile2", function() {
		$(this).addClass("mouseover");

	});

	$("div.tileMap2").on("mouseout", ".tile2", function() {
		$(this).removeClass("mouseover");
	});

	$("div.tileMap2")
			.on(
					"click",
					".tile2",
					function() {
						$(".tileMap2 .active").removeClass("active");
						$(this).addClass("active");

						var totalNum = $("div.tile2").index($(this))
						var RowNum = $("div.tileMap2 > div:first > .tile2").length;

						var drw_code = $(".drw_code").val();
						var X_index = parseInt(totalNum / RowNum);
						var Y_index = totalNum % RowNum;

						var goods_info = $("#tile_goodsLoList");

						goods_info.empty();

						goods_info.append($("<h3></h3>").text("배정된 물품"));
						goods_info
								.append($("<table class='table table-hover tileGoodsLo'></table>"));
						$(".tileGoodsLo").append(
								$("<thead class='tgGoods'></thead>"));
						$(".tgGoods").append($("<tr class='TthTr'></tr>"));
						$(".TthTr").append($("<th></th>").text("물품번호"));
						$(".TthTr").append($("<th></th>").text("물품이름"));
						$(".TthTr").append($("<th></th>").text("물품가격"));
						$(".tileGoodsLo").append(
								$("<tbody class='tile_goodsLoList'></tbody>"));

						$
								.ajax({

									url : "goods_locationList",
									type : "get",
									data : {
										drw_code : drw_code,
										tile_crdnt_x : X_index,
										tile_crdnt_y : Y_index
									},
									dataType : "json",
									success : function(data) {
										if (data.length > 0) {
											for (var i = 0; i < data.length; i++) {
												$(".tile_goodsLoList")
														.append(
																$(
																		"<tr class='goodsLo'></tr>")
																		.attr(
																				"data-id",
																				data[i].goods_code));
												$(
														".goodsLo[data-id="
																+ data[i].goods_code
																+ "]")
														.append(
																$("<td></td>")
																		.text(
																				data[i].goods_code));
												$(
														".goodsLo[data-id="
																+ data[i].goods_code
																+ "]")
														.append(
																$("<td></td>")
																		.text(
																				data[i].goods_nm));
												$(
														".goodsLo[data-id="
																+ data[i].goods_code
																+ "]")
														.append(
																$("<td></td>")
																		.text(
																				thousandSeparatorCommas(data[i].goods_pc)));
											}

										} else {
											$(".tile_goodsLoList")
													.append(
															$("<tr></tr>")
																	.append(
																			$(
																					"<td colspan='4'></td>")
																					.text(
																							"물품이 존재하지 않습니다.")));
										}
									}

								});

					});

	var setTileCategory = function(jObject) {

		$.ajax({
			url : "setReTileCategory",
			type : "post",
			contentType : "application/json;charset=UTF-8",
			data : JSON.stringify(jObject),
			dataType : "text",
			success : function(data) {
				console.log("카테고리 성공" + data);
			},
			error : function(data) {

			}
		});

	}

	var setGoodsLocation = function(json) {

		$.ajax({
			url : "setGoods_location",
			type : "post",
			contentType : "application/json;charset=UTF-8",
			data : JSON.stringify(json),
			dataType : "text",
			success : function(data) {
				console.log("물품 성공" + data);
				var floor = $("#floor").val();
				imgLoad(floor);
				productImgLoad(floor);
				goods_locationTile();
			},
			error : function(data) {

			}
		});

	}

	$("#tile_goods")
			.on(
					"click",
					"tr",
					function() {
						
						$("#tile_goods td").css("border", "");
						$(this).children().first().css("border-left", "red 2px solid");
						$(this).children().css("border-top", "red 2px solid");
						$(this).children().css("border-bottom", "red 2px solid");
						$(this).children().last().css("border-right", "red 2px solid");

						var totalNum = $("div.tile").index(
								$(".tileMap .active"));
						var RowNum = $("div.tileMap > div:first > .tile").length;

						var user_group = $(this).find("td:first").text();

						var drw_code = $("#drw_code").val();
						var X_index = parseInt(totalNum / RowNum);
						var Y_index = totalNum % RowNum;

						var age = $(this).find("td:first").text().split("/")[0];
						var gender = $(this).find("td:first").text().split("/")[1];

						if (gender == "남성") {
							gender = "m";
						} else {
							gender = "w";
						}

						var marry = $(this).find("td:first").text().split("/")[2];

						if (marry == "미혼") {
							marry = "no";
						} else {
							marry = "yes";
						}

						$
								.ajax({
									url : "goods_graph",
									type : "POST",
									contentType : "application/json;charset=UTF-8",
									data : JSON.stringify({
										drw_code : drw_code,
										tile_crdnt_x : X_index,
										tile_crdnt_y : Y_index,
										user_mrrg_at : marry,
										user_sexdstn : gender,
										age : age
									}),
									dataType : "json",
									success : function(data) {
										console.log(data);
										var length = data.goods_graph.length;

										if (length > 0) {
											var options = {

												title : {
													text : user_group
															+ ' 코너 물품 매출 5순위'
												},
												xAxis : {
													categories : []
												},
												series : [ {
													type : 'column',
													colorByPoint : true,
													data : [],
													showInLegend : false
												} ]

											}

											for (var i = 0; i < length; i++) {

												options.xAxis.categories[i] = data.goods_graph[i].goods_nm;
												options.series[0].data[i] = parseInt(data.goods_graph[i].totalPrice);

											}

											Highcharts.chart('goods_graph',
													options);

										} else {
											$("#goods_graph")
													.html(
															"<h2 style='line-height:300px'>매출이 없습니다.</h2>");

										}

									}
								});

					});
</script>