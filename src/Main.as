package  
{
	import cepa.utils.ToolTip;
	import fl.transitions.easing.None;
	import fl.transitions.easing.Regular;
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.setTimeout;
	import flash.utils.Timer;
	import org.papervision3d.core.math.Number3D;
	import org.papervision3d.core.utils.Mouse3D;
	import org.papervision3d.events.InteractiveScene3DEvent;
	import org.papervision3d.materials.BitmapFileMaterial;
	import org.papervision3d.materials.BitmapMaterial;
	import org.papervision3d.materials.ColorMaterial;
	import org.papervision3d.materials.shaders.FlatShader;
	import org.papervision3d.materials.shaders.GouraudShader;
	import org.papervision3d.materials.shaders.ShadedMaterial;
	import org.papervision3d.objects.DisplayObject3D;
	import org.papervision3d.objects.primitives.Cylinder;
	import org.papervision3d.objects.primitives.Sphere;
	import org.papervision3d.view.BasicView;
	import org.papervision3d.view.layer.ViewportLayer;
	import pipwerks.SCORM;
	
	/**
	 * ...
	 * @author Alexandre
	 */
	public class Main extends BasicView
	{
		/**
		 * @private
		 * Posição do click na tela.
		 */
		private var clickPoint:Point =  new Point();
		
		/**
		 * @private
		 * Utilizado para cálculo da rotação da câmera.
		 */
		public var theta:Number;
		
		/**
		 * @private
		 * Utilizado para cálculo da rotação da câmera.
		 */
		public var phi:Number; 
		
		/**
		 * @private
		 * Ponto onde o mouse foi solto.
		 * Utilizado para movimentação da câmera.
		 */
		private var upPoint:Point = new Point();
		
		/**
		 * @private
		 * Esfera que será usada como mapa.
		 */
		private var sphere:Sphere;
		
		/**
		 * @private
		 * Mouse3D usado para calcular a posição 3D no mapa.
		 */
		private var mouse3D:Mouse3D;
		
		/**
		 * @private
		 * Vetor que representa a direção y da câmera, impedindo que ela rotacione ao ficar invertida (de ponta cabeça).
		 */
		private var upVector:Number3D;
		
		/**
		 * @private
		 * Fator de multiplicação de distância da câmera.
		 */
		public var distance:Number = 1000;
		
		/**
		 * @private
		 * Alfinete que representa o local do click feito pelo usuário.
		 */
		private var alfineteClick:Alfinete;
		
		/*
		 * Filtro de conversão para tons de cinza.
		 */
		private const GRAYSCALE_FILTER:ColorMatrixFilter = new ColorMatrixFilter([
			0.2225, 0.7169, 0.0606, 0, 0,
			0.2225, 0.7169, 0.0606, 0, 0,
			0.2225, 0.7169, 0.0606, 0, 0,
			0.0000, 0.0000, 0.0000, 1, 0
		]);
		
		private var latitudeSorted:Number;
		private var longitudeSorted:Number;
		
		private var latitudeClick:Number;
		private var longitudeClick:Number;
		
		private var orientacoesScreen:InstScreen;
		private var creditosScreen:AboutScreen;
		private var feedbackScreen:FeedBackScreen;
		
		private var xmlConfig:XML;
		private var configLoaded:Boolean = false;
		
		private var bmpFundo:BitmapData;
		private var imgFundo:Bitmap;
		
		private var configuracoes:Array = [];
		private var txtFormat:TextFormat = new TextFormat("arial", 15, 0xFFFFFF, true);
		
		private var respondido:Boolean = false;
		
		public function Main() 
		{
			super(700, 480, false, true);
			if (stage) init(null);
			else addEventListener(Event.ADDED_TO_STAGE, init);
			
		}
		
		/**
		 * @private
		 * Inicia atividade.
		 */
		private function init(e:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			this.scrollRect = new Rectangle(0, 0, 700, 500);
			
			
			
			creditosScreen = new AboutScreen();
			addChild(creditosScreen);
			orientacoesScreen = new InstScreen();
			addChild(orientacoesScreen);
			feedbackScreen = new FeedBackScreen();
			addChild(feedbackScreen);
			
			inicializaParametros();
			startRendering();
			createSphere();
			adicionaListeners();
			
			loadConfig();
			
			//stage.displayState = StageDisplayState.FULL_SCREEN;
			stage.scaleMode = StageScaleMode.SHOW_ALL;
			
			interactiveViewPort();
			interactiveMouse();
			rotating(null);
			setChildIndex(bordaAtividade, numChildren - 1);
			
			iniciaTutorial();
			
			if (ExternalInterface.available) initLMSConnection();
		}
		
		private function loadConfig():void 
		{
			var urlReq:URLRequest = new URLRequest("config.xml");
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, readXML);
			urlLoader.load(urlReq);
		}
		
		private function readXML(e:Event):void 
		{
			xmlConfig = new XML(e.target.data);
			
			/*for each (var item:Object in xmlConfig.locais) 
			{
				configuracoes.push(item);
			}*/
			
			var i:int = 0;
			while (xmlConfig.locais.local[i] != null)
			{
				var obj:Object = {
					nome: xmlConfig.locais.local[i].name,
					latitude: xmlConfig.locais.local[i].latitude,
					longitude: xmlConfig.locais.local[i].longitude,
					mensagem: xmlConfig.locais.local[i].mensagem,
					imagem: xmlConfig.locais.local[i].imagem
				}
				configuracoes.push(obj);
				i++;
			}
			
			sortConfig();
			
			configLoaded = true;
		}
		
		private var sortedExercise:int = 0;
		private function sortConfig():void 
		{
			var rand:int = Math.floor(Math.random() * configuracoes.length);
			while (rand == sortedExercise) {
				rand = Math.floor(Math.random() * configuracoes.length);
			}
			
			sortedExercise = rand;
			//var rand:int = 0;
			
			latitudeSorted = Number(configuracoes[rand].latitude);
			longitudeSorted = Number(configuracoes[rand].longitude);
			TextField(barraInstrucao).defaultTextFormat = txtFormat;
			barraInstrucao.text = String(configuracoes[rand].mensagem);
			
			var urlRequest:URLRequest = new URLRequest(String(configuracoes[rand].imagem));
			var urlLoader:Loader = new Loader();
			urlLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadImage, false, 0, true);
			urlLoader.load(urlRequest);
		}
		
		private function loadImage(e:Event):void 
		{
			var obj:Bitmap = Bitmap(LoaderInfo(e.target).content);
			
			if(imgFundo != null) options.removeChild(imgFundo);
			
			imgFundo = new Bitmap(obj.bitmapData);
			options.addChild(imgFundo);
			imgFundo.x = options.boxMask.x - options.boxMask.width / 2;
			imgFundo.y = options.boxMask.y - options.boxMask.height / 2;
			imgFundo.mask = options.boxMask;
			
			//imgFundo.bitmapData.draw(obj);
			//if(imgFundo.bitmapData != null) imgFundo.bitmapData.draw(MovieClip(options.boxMask),);
			//imgFundo.bitmapData = obj.bitmapData;
			//imgFundo = new Bitmap(obj.bitmapData);
		}
		
		/**
		 * @private
		 * Inicializa os parâmetros necessários a atividade.
		 */
		private function inicializaParametros():void
		{
			btOk.filters = [GRAYSCALE_FILTER];
			btOk.mouseEnabled = false;
			btOk.alpha = 0.5;
			
			/*imgFundo = new Bitmap();
			options.addChild(imgFundo);
			imgFundo.x = options.boxMask.x - options.boxMask.width / 2;
			imgFundo.y = options.boxMask.y - options.boxMask.height / 2;
			imgFundo.mask = options.boxMask;*/
			
			//latText.visible = false;
			//longText.visible = false;
			//latitude.visible = false;
			//longitude.visible = false;
		}
		
		/**
		 * Adiciona eventListener aos objetos no stage.
		 */
		private function adicionaListeners():void
		{
			btOk.addEventListener(MouseEvent.CLICK, verificaCoordenadas);
			//btCancel.addEventListener(MouseEvent.CLICK, calcelHandler);
			btNew.addEventListener(MouseEvent.CLICK, reset);
			
			botoes.tutorialBtn.addEventListener(MouseEvent.CLICK, iniciaTutorial);
			botoes.orientacoesBtn.addEventListener(MouseEvent.CLICK, openOrientacoes);
			botoes.resetButton.addEventListener(MouseEvent.CLICK, reset);
			botoes.creditos.addEventListener(MouseEvent.CLICK, openCreditos);
			
			stage.addEventListener(MouseEvent.MOUSE_DOWN, initRotation);
			
			createToolTips();
		}
		
		private function openOrientacoes(e:MouseEvent):void 
		{
			orientacoesScreen.openScreen();
			setChildIndex(orientacoesScreen, numChildren - 1);
			setChildIndex(bordaAtividade, numChildren - 1);
		}
		
		private function openCreditos(e:MouseEvent):void 
		{
			creditosScreen.openScreen();
			setChildIndex(creditosScreen, numChildren - 1);
			setChildIndex(bordaAtividade, numChildren - 1);
		}
		
		private function createToolTips():void 
		{
			var infoTT:ToolTip = new ToolTip(botoes.creditos, "Créditos", 12, 0.8, 100, 0.6, 0.1);
			var instTT:ToolTip = new ToolTip(botoes.orientacoesBtn, "Orientações", 12, 0.8, 100, 0.6, 0.1);
			var resetTT:ToolTip = new ToolTip(botoes.resetButton, "Reiniciar", 12, 0.8, 100, 0.6, 0.1);
			var intTT:ToolTip = new ToolTip(botoes.tutorialBtn, "Reiniciar tutorial", 12, 0.8, 150, 0.6, 0.1);
			
			var finalizaTT:ToolTip = new ToolTip(btOk, "Finalizar atividade", 12, 0.8, 200, 0.6, 0.1);
			var novoTT:ToolTip = new ToolTip(btNew, "Sortear localização", 12, 0.8, 250, 0.6, 0.1);
			
			addChild(infoTT);
			addChild(instTT);
			addChild(resetTT);
			addChild(intTT);
			addChild(finalizaTT);
			addChild(novoTT);
		}
		
		private function verificaCoordenadas(e:MouseEvent):void 
		{
			if (!respondido) nTentativas++;
			
			var currentScore:Number;
			//trace("ans: " + latitudeSorted + ", " + longitudeSorted);
			//trace("click: " + latitudeClick + ", " + longitudeClick);
			if (Math.abs(latitudeSorted - latitudeClick) <= 2 && Math.abs(longitudeSorted - longitudeClick) <= 2)
			{
				feedbackScreen.setText("Parabéns!\nVocê encontrou " + String(configuracoes[sortedExercise].nome) + "!");
				currentScore = 100;
			}else{
				feedbackScreen.setText("Procure novamente...");
				currentScore = 0;
			}
			
			if (!respondido){
				score = (score * (nTentativas - 1) + currentScore) / nTentativas;
				
				if (score >= 50) completed = true;
				commit();
			}
			
			respondido = true;
			
			btOk.mouseEnabled = false;
			btOk.alpha = 0.5;
			btOk.filters = [GRAYSCALE_FILTER];
		}
		
		private function reset(e:MouseEvent):void 
		{
			inicializaParametros();
			
			if (alfineteClick != null)
			{
				scene.removeChild(alfineteClick);
				alfineteClick = null;
			}
			
			//upPoint.x = -1260;
			//upPoint.y = 450;
			
			if(e.target == btOk){
				theta = -3.137547476611862;
				phi = 1.5743194505715339;
				rotating(null);
			}
			
			sortConfig();
			respondido = false;
		}
		
		/**
		 * @private
		 * Torna o viewport interativo.
		 */
		private function interactiveViewPort():void
		{
			viewport.interactive = true;
			
			camera.target = null;
			//upPoint.x = -1260;
			//upPoint.y = 450;
			theta = -3.137547476611862;
			phi = 1.5743194505715339;
		}
		
		/**
		 * @private
		 * habilita o Mouse3D e instancia a variável mouse3D.
		 */
		private function interactiveMouse():void
		{
			//Habilita o Mouse3D.
			Mouse3D.enabled = true;
			
			//Cria o mouse3D.
			mouse3D = viewport.interactiveSceneManager.mouse3D;
			
			//alfineteClick = new Alfinete();
			if (alfineteClick == null)
			{
				alfineteClick = new Alfinete();
				alfineteClick.copyTransform(mouse3D);
				//scene.addChild(alfineteClick);
			}
		}
		
		/**
		 * @private
		 * Cria a esfera.
		 */
		private function createSphere():void
		{
			//Cria um bitmapData com a imagem adicionada.
			var earthBmp:BitmapData = new EarthMap();
			//Cria um BitmapMaterial com o bitmap criado com a imagem.
			var earthMaterial:BitmapMaterial = new BitmapMaterial(earthBmp);
			//Torna o BitmapMatrial interativo(passível de clicks).
			earthMaterial.interactive = true;
			
			//Cria um shader.
			//var shader:GouraudShader = new GouraudShader(null, 0xFFFFFF, 0x000000);
			var shader:FlatShader = new FlatShader(null, 0xFFFFFF, 0x000000);
			
			//Cria um shadedMaterial para ser usado como material da esfera.
			var shadedMaterial:ShadedMaterial = new ShadedMaterial(earthMaterial, shader);
			shadedMaterial.interactive = true;
			
			//Cria a esfera com o material dado(earthMaterial ou shadedMaterial).
			//sphere = new Sphere(earthMaterial, 400, 24, 18);
			sphere = new Sphere(shadedMaterial, 480, 36, 18);
			
			scene.addChild(sphere);
			
			//addEventListener(MouseEvent.MOUSE_DOWN, clickHandler);
			sphere.addEventListener(InteractiveScene3DEvent.OBJECT_CLICK, sphereClickHandler); 
		}
		
		/**
		 * @private
		 * Trata o clique na esfera.
		 */
		private function sphereClickHandler(e:InteractiveScene3DEvent):void 
		{
			if (distClick > 2 || !configLoaded) return;
			if (respondido) return;
			
			if (alfineteClick != null) 
			{
				scene.removeChild(alfineteClick);
				alfineteClick = null;
			}
			
			alfineteClick = new Alfinete();
			alfineteClick.copyTransform(mouse3D);
			scene.addChild(alfineteClick);
			
			var phiRotation:Number = Math.acos(mouse3D.y / 400) * 180 / Math.PI;
			var thetaRotation:Number = Math.atan2(mouse3D.z, mouse3D.x) * 180 / Math.PI;
			
			var raio:Number = Math.sqrt(Math.pow(mouse3D.x, 2)+Math.pow(mouse3D.y, 2)+Math.pow(mouse3D.z, 2));
			
			var phi:Number = 90 - (Math.acos(mouse3D.y / raio)*180/Math.PI);
			
			var theta:Number = Math.atan2(mouse3D.z, mouse3D.x)*180/Math.PI + 180;
			
			var latitudeGraus:int = Math.floor(phi);
			var latitudeMin:int = Math.floor((phi - latitudeGraus) * 60);
			var latitudeSeg:int = Math.round(((phi - latitudeGraus) * 60 - latitudeMin) * 60);
			
			//trace("latitude: " + latitudeGraus + "º " + latitudeMin + "\' " + latitudeSeg + "\"");
			//latitude.text = String(latitudeGraus) + "º " + String(latitudeMin) + "\' " + String(latitudeSeg) + "\"";
			
			var longitudeGraus:int;
			var longitudeMin:int;
			var longitudeSeg:int;
			
			if (theta > 180) 
			{
				longitudeGraus = Math.floor(theta) - 360;
				var longitudeGrausAux:int = Math.floor(theta);
				longitudeMin = Math.floor((theta - longitudeGrausAux) * 60);
				longitudeSeg = Math.round(((theta - longitudeGrausAux) * 60 - longitudeMin) * 60);
			}
			else 
			{
				longitudeGraus = Math.floor(theta);
				longitudeMin = Math.floor((theta - longitudeGraus) * 60);
				longitudeSeg = Math.round(((theta - longitudeGraus) * 60 - longitudeMin) * 60);
			}
			
			//trace("longitude: " + longitudeGraus + "º " + longitudeMin + "\' " + longitudeSeg + "\"");
			//longitude.text = String(longitudeGraus) + "º " + String(longitudeMin) + "\' " + String(longitudeSeg) + "\""
			
			latitudeClick = latitudeGraus;
			longitudeClick = longitudeGraus;
			
			btOk.filters = [];
			btOk.mouseEnabled = true;
			btOk.alpha = 1;
			//btCancel.visible = true;
			
			//latText.visible = true;
			//longText.visible = true;
			//latitude.visible = true;
			//longitude.visible = true;
			
		}
		
		private var distClick:Number = 0;
		private var clickPt:Point = new Point();
		
		/**
		 * @private
		 * Inicia o processo de rotação da câmera.
		 */
		private function initRotation(e:MouseEvent):void 
		{
			//if (e.target is Stage)
			//{
				if (tweenRotTheta != null) {
					if (tweenRotTheta.isPlaying) tweenRotTheta.stop();
				}
				if (tweenRotPhi != null) {
					if (tweenRotPhi.isPlaying) tweenRotPhi.stop();
				}
				
				stage.addEventListener(Event.ENTER_FRAME, rotating);
				stage.addEventListener(MouseEvent.MOUSE_UP, stopRotating);
				clickPoint.x = stage.mouseX;
				clickPoint.y = stage.mouseY;
				clickPt.x = stage.mouseX;
				clickPt.y = stage.mouseY;
			//}
		}
		
		private var lastDtheta:Number;
		private var lastDphi:Number;
		
		/**
		 * @private
		 * Rotação da câmera.
		 */
		private function rotating(e:Event):void 
		{
			distClick = Point.distance(clickPt, new Point(stage.mouseX, stage.mouseY));
			
			if(e != null){
				//theta = ((upPoint.x - (stage.mouseX - clickPoint.x)) / stage.stageWidth * 100) * Math.PI / 180;// % 360; 
				//phi = ((upPoint.y - (stage.mouseY - clickPoint.y)) / stage.stageHeight * 100 ) * Math.PI / 180;// % 360;
				lastDtheta = ((stage.mouseX - clickPoint.x) / 10) * Math.PI / 180;
				lastDphi = ((stage.mouseY - clickPoint.y) / 10) * Math.PI / 180;
				if (upVector.y < 0) {
					theta += lastDtheta;
				}else{
					theta -= lastDtheta;
				}
				phi -= lastDphi;
			}else {
				//theta *= Math.PI / 180;// % 360; 
				//phi *= Math.PI / 180;// % 360;
			}
			
			if (theta == 0) theta = 0.001;
			if (phi == 0) phi = 0.001;
			
			//trace(theta, phi);
			
			camera.x = distance * Math.cos(theta) * Math.sin(phi); 
			camera.z = distance * Math.sin(theta) * Math.sin(phi); 
			camera.y = distance * Math.cos(phi); 
			
			//trace(camera.x, camera.y, camera.z);
			
			if (Math.sin(phi) < 0) upVector = new Number3D(0, -1, 0); 
			else upVector = new Number3D(0, 1, 0);
			camera.lookAt(sphere , upVector);
			
			clickPoint.x = stage.mouseX;
			clickPoint.y = stage.mouseY;
		}
		
		/**
		 * @private
		 * Para a rotação da câmera.
		 */
		private function stopRotating(e:MouseEvent):void 
		{
			setTimeout(zeraDist, 100);
			stage.removeEventListener(Event.ENTER_FRAME, rotating);
			stage.removeEventListener(MouseEvent.MOUSE_UP, stopRotating);
			
			//upPoint.x = upPoint.x - (stage.mouseX - clickPoint.x);
			//upPoint.y = upPoint.y - (stage.mouseY - clickPoint.y);
			continueRotating();
		}
		
		private function zeraDist():void
		{
			distClick = 0;
		}
		
		private var fat:Number = 10;
		private var tweenRotTheta:Tween;
		private var tweenRotPhi:Tween;
		private var tweenPropTheta:Sprite = new Sprite();
		private var tweenPropPhi:Sprite = new Sprite();
		private var invertTheta:Boolean = false;
		private function continueRotating():void
		{
			if (lastDtheta != 0) {
				if (upVector.y < 0) {
					invertTheta = true;
				}else{
					invertTheta = false;
				}
				tweenRotTheta = new Tween(tweenPropTheta, "x", Regular.easeOut, lastDtheta * fat, 0, 1, true);
				tweenRotTheta.addEventListener(TweenEvent.MOTION_CHANGE, changeRotation);
			}
			if (lastDphi != 0) {
				tweenRotPhi = new Tween(tweenPropPhi, "x", Regular.easeOut, lastDphi * fat, 0, 1, true);
				tweenRotPhi.addEventListener(TweenEvent.MOTION_CHANGE, changeRotation);
			}
			
		}
		
		private function changeRotation(e:TweenEvent):void 
		{
			if (e.target == tweenRotTheta) {
				if (invertTheta) {
					theta += tweenPropTheta.x / fat;
				}else{
					theta -= tweenPropTheta.x / fat;
				}
			}else {
				phi -= tweenPropPhi.x / fat;
			}
			rotating(null);
		}
		
		
		//Tutorial
		private var balao:CaixaTexto;
		private var pointsTuto:Array;
		private var tutoBaloonPos:Array;
		private var tutoPos:int;
		private var tutoPhaseFinal:Boolean;
		private var tutoSequence:Array = ["Clique e arraste o mouse para alterar a visualização.",
										  "Clique no globo para marcar uma posição.",
										  "Pressione \"terminei\" quando tiver concluído."];
										  
		private function iniciaTutorial(e:MouseEvent = null):void 
		{
			tutoPos = 0;
			tutoPhaseFinal = false;
			if(balao == null){
				balao = new CaixaTexto(true);
				addChild(balao);
				balao.visible = false;
				
				pointsTuto = 	[new Point(300, 250),
								new Point(400, 250),
								new Point(btOk.x + btOk.width/ 2, btOk.y)];
								
				tutoBaloonPos = [[CaixaTexto.RIGHT, CaixaTexto.FIRST],
								[CaixaTexto.LEFT, CaixaTexto.FIRST],
								[CaixaTexto.LEFT, CaixaTexto.FIRST]];
			}
			balao.removeEventListener(Event.CLOSE, closeBalao);
			feedbackScreen.removeEventListener(Event.CLOSE, iniciaTutorialSegundaFase);
			
			balao.setText(tutoSequence[tutoPos], tutoBaloonPos[tutoPos][0], tutoBaloonPos[tutoPos][1]);
			balao.setPosition(pointsTuto[tutoPos].x, pointsTuto[tutoPos].y);
			balao.addEventListener(Event.CLOSE, closeBalao);
			balao.visible = true;
		}
		
		private function closeBalao(e:Event):void 
		{
			if (tutoPhaseFinal) {
				balao.removeEventListener(Event.CLOSE, closeBalao);
				balao.visible = false;
				feedbackScreen.removeEventListener(Event.CLOSE, iniciaTutorialSegundaFase);
			}else{
				tutoPos++;
				if (tutoPos >= tutoSequence.length) {
					balao.removeEventListener(Event.CLOSE, closeBalao);
					balao.visible = false;
					feedbackScreen.addEventListener(Event.CLOSE, iniciaTutorialSegundaFase);
					tutoPhaseFinal = true;
				}else {
					balao.setText(tutoSequence[tutoPos], tutoBaloonPos[tutoPos][0], tutoBaloonPos[tutoPos][1]);
					balao.setPosition(pointsTuto[tutoPos].x, pointsTuto[tutoPos].y);
				}
			}
		}
		
		private function iniciaTutorialSegundaFase(e:Event):void 
		{
			if(tutoPhaseFinal){
				balao.setText("Você pode tentar quantas vezes quiser. Basta marcar uma nova posição.", tutoBaloonPos[1][0], tutoBaloonPos[1][1]);
				balao.setPosition(pointsTuto[1].x, pointsTuto[1].y);
				tutoPhaseFinal = false;
			}
		}
		
		
		/*------------------------------------------------------------------------------------------------*/
		//SCORM:
		
		private const PING_INTERVAL:Number = 5 * 60 * 1000; // 5 minutos
		private var completed:Boolean;
		private var scorm:SCORM;
		private var scormExercise:int;
		private var connected:Boolean;
		private var score:int;
		private var pingTimer:Timer;
		private var nTentativas:int = 0;
		
		/**
		 * @private
		 * Inicia a conexão com o LMS.
		 */
		private function initLMSConnection () : void
		{
			completed = false;
			connected = false;
			scorm = new SCORM();
			
			pingTimer = new Timer(PING_INTERVAL);
			pingTimer.addEventListener(TimerEvent.TIMER, pingLMS);
			
			connected = scorm.connect();
			
			if (connected) {
				// Verifica se a AI já foi concluída.
				var status:String = scorm.get("cmi.completion_status");	
				var stringScore:String = scorm.get("cmi.score.raw");
				var stringTentativas:String = scorm.get("cmi.suspend_data");
			 
				switch(status)
				{
					// Primeiro acesso à AI
					case "not attempted":
					case "unknown":
					default:
						completed = false;
						break;
					
					// Continuando a AI...
					case "incomplete":
						completed = false;
						break;
					
					// A AI já foi completada.
					case "completed":
						completed = true;
						break;
				}
				
				//unmarshalObjects(mementoSerialized);
				scormExercise = 1;
				if (stringScore != "") score = Number(stringScore.replace(",", "."));
				else score = 0;
				
				if (stringTentativas != "") nTentativas = int(stringTentativas);
				else nTentativas = 0;
				
				var success:Boolean = scorm.set("cmi.score.min", "0");
				if (success) success = scorm.set("cmi.score.max", "100");
				
				if (success)
				{
					scorm.save();
					pingTimer.start();
				}
				else
				{
					//trace("Falha ao enviar dados para o LMS.");
					connected = false;
				}
			}
			else
			{
				trace("Esta Atividade Interativa não está conectada a um LMS: seu aproveitamento nela NÃO será salvo.");
			}
			
			//reset();
		}
		
		/**
		 * @private
		 * Salva cmi.score.raw, cmi.location e cmi.completion_status no LMS
		 */ 
		private function commit()
		{
			if (connected)
			{
				scorm.set("cmi.exit", "suspend");
				
				// Salva no LMS a nota do aluno.
				var success:Boolean = scorm.set("cmi.score.raw", score.toString());

				// Notifica o LMS que esta atividade foi concluída.
				success = scorm.set("cmi.completion_status", (completed ? "completed" : "incomplete"));

				// Salva no LMS o exercício que deve ser exibido quando a AI for acessada novamente.
				success = scorm.set("cmi.location", scormExercise.toString());
				
				// Salva no LMS a string que representa a situação atual da AI para ser recuperada posteriormente.
				success = scorm.set("cmi.suspend_data", String(nTentativas));

				if (success)
				{
					scorm.save();
				}
				else
				{
					pingTimer.stop();
					//setMessage("Falha na conexão com o LMS.");
					connected = false;
				}
			}
		}
		
		/**
		 * @private
		 * Mantém a conexão com LMS ativa, atualizando a variável cmi.session_time
		 */
		private function pingLMS (event:TimerEvent)
		{
			//scorm.get("cmi.completion_status");
			commit();
		}
	}

}