package 
{
	import fl.transitions.easing.None;
	import fl.transitions.Tween;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	import flash.utils.Timer;
	import pipwerks.SCORM;

	
	public class Main extends Sprite
	{
		//--------------------------------------------------
		// Membros públicos (interface).
		//--------------------------------------------------
		//Mensagens mostradas ao usuário.
		static public const MSG_COMPLETED:String = "Você já completou o exercício.\nVocê pode refazer o exercício quantas vezes quiser, porém não valerá nota.";
		static public const MSG_INCOMPLETE:String = "O exercício está valendo nota, portanto preste bastante atenção!";
		private var MSG_COMPLETED_EXTENDED:String = " (de 100 pontos). Você pode refazer o exercício quantas vezes quiser, porém não valerá nota.\nClique sobre uma função para ver seu grupo (função e derivada).";
		private var MSG_FINISHED:String = " (de 100 pontos). Clique sobre uma função para ver seu grupo (função e derivada).";
		static public const INICIO_MSG:String = "Sua nota foi "; 
		
		/**
		 * Cria um novo objeto desta classe.
		 */
		public function Main ()
		{
			init();
		}
		
		/**
		 * Restaura a CONFIGURAÇÃO inicial (padrão).
		 */
		public function reset (e:MouseEvent = null)
		{
			okButon.removeEventListener(MouseEvent.CLICK, debugPosicoes);
			nextButton.removeEventListener(MouseEvent.CLICK, reset);
			valendoNota.removeEventListener(MouseEvent.CLICK, mostraTelaValendo);
			telaMensagens.okBTN.removeEventListener(MouseEvent.CLICK, escondeTelaMensagem);
			removeListenerArrastePecas();
			
			initListaFuncoes();
			sorteiaFuncoes();
			posicionaPecas();
			
			funcao.visible = false;
			derivadaPrimeira.visible = false;
			derivadaSegunda.visible = false;
			calculaPontuacao = true;
			telaMensagens.visible = false;
			
			pontuacao = 0;
			
			addListeners();
			
			verificaStatusLMS();
		}
		
		//--------------------------------------------------
		// Membros privados.
		//--------------------------------------------------
		
		private const VIEWPORT:Rectangle = new Rectangle(0, 0, 700, 500);
		
		private const ORDEM_MATRIX:Point = new Point(3, 3); //Numero funcoes x numero de frames
		
		private const NUM_TOTAL_FUNCOES:Number = 8;
		
		private const filtroErrado:GlowFilter = new GlowFilter(0xFF0000, 1, 10, 10, 2, 1);
		private const filtroGrupo:GlowFilter = new GlowFilter(0x008000, 1, 10, 10, 2, 1);
		
		private var listaFuncoes:Array;
		private var arrayPecas:Array;
		private var funcoesSorteadas:Array;
		private var dragingMC:MovieClip;
		private var dropTargetMC:MovieClip;
		private var inicialPosition:Point;
		
		private var dicionarioPecas:Dictionary;
		private var pecasDicionario:Dictionary;
		
		private var tweenXDraging:Tween;
		private var tweenYDraging:Tween;
		
		private var tweenXDropTarget:Tween;
		private var tweenYDropTarget:Tween;
		private var pontuacao:Number;
		
		private var calculaPontuacao:Boolean;
		private var valendoBoolean:Boolean;
		
		
		/**
		 * @private
		 * Inicialização (CRIAÇÃO DE OBJETOS) independente do palco (stage).
		 */
		private function init () : void
		{
			scrollRect = VIEWPORT;
			
			if (stage) stageDependentInit();
			else addEventListener(Event.ADDED_TO_STAGE, stageDependentInit);
		}
		
		/**
		 * @private
		 * Inicialização (CRIAÇÃO DE OBJETOS) dependente do palco (stage).
		 */
		private function stageDependentInit (event:Event = null) : void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, stageDependentInit);
			
			telaValendo.visible = false;
			telaMensagens.visible = false;
			funcao.visible = false;
			derivadaPrimeira.visible = false;
			derivadaSegunda.visible = false;
			calculaPontuacao = true;
			infoScreen.visible = false;
			aboutScreen.visible = false;
			
			pontuacao = 0;
			
			initLMSConnection();
			
			initListaFuncoes();
			sorteiaFuncoes();
			posicionaPecas();
			
			addListeners();
			
			verificaStatusLMS();
			
			botoes.orientacoesBtn.addEventListener(MouseEvent.CLICK, openCloseInfoScreen);
			infoScreen.addEventListener(MouseEvent.CLICK, openCloseInfoScreen);
			botoes.creditos.addEventListener(MouseEvent.CLICK, openCloseAboutScreen);
			aboutScreen.addEventListener(MouseEvent.CLICK, openCloseAboutScreen);
			
			openCloseInfoScreen();
		}
		
		private function openCloseAboutScreen(e:MouseEvent):void 
		{
			if (aboutScreen.visible) aboutScreen.play();
			else {
				aboutScreen.gotoAndStop(1);
				aboutScreen.visible = true;
				setChildIndex(aboutScreen, numChildren - 1);
			}
		}
		
		//Abre/fecha tela de informações
		private function openCloseInfoScreen(e:MouseEvent = null):void 
		{
			if (infoScreen.visible) infoScreen.play();
			else {
				infoScreen.gotoAndStop(1);
				infoScreen.visible = true;
				setChildIndex(infoScreen, numChildren - 1);
			}
		}
		
		//Abre/fecha a barra de menu utilizando tween
		/*private function openCloseMenu(e:MouseEvent):void 
		{
			if(tweenMenu == null || !tweenMenu.isPlaying){
				if (menuBar.y < 450) {
					tweenMenu = new Tween(menuBar, "y", None.easeNone, menuBar.y, 477, 0.3, true);
					menuBar.upDown.gotoAndStop("ABRIR");
				}
				else {
					tweenMenu = new Tween(menuBar, "y", None.easeNone, menuBar.y, 442, 0.3, true);
					menuBar.upDown.gotoAndStop("FECHAR");
				}
			}
		}*/
		
		//Após carregada a atividade verifica-se o status da atividade e aplica-se as modificações de acordo com o status.
		private function verificaStatusLMS():void
		{
			if (completed) {
				//fraseCompleted.visible = true;
				valendoNota.visible = false;
				valendoBoolean = false;
				nextButton.visible = true;
				abreTelaMensagem(MSG_COMPLETED);
			}else {
				if (lastTimes > 0){
					//fraseCompleted.visible = false;
					valendoNota.visible = false;
					nextButton.visible = false;
					valendoBoolean = true;
					abreTelaMensagem(MSG_INCOMPLETE);
				}
				else {
					//fraseCompleted.visible = false;
					valendoNota.visible = true;
					nextButton.visible = true;
					valendoBoolean = false;
				}
			}
		}
		
		//Abre a tela de mensagens com a mensagem passada como parâmetro.
		private function abreTelaMensagem(mensagem:String):void
		{
			telaMensagens.mensagem.text = mensagem;
			telaMensagens.visible = true;
			setChildIndex(telaMensagens, numChildren - 1);
		}
		
		//Fecha a tela de mensagens.
		private function escondeTelaMensagem(e:MouseEvent):void 
		{
			telaMensagens.visible = false;
		}
		
		//Adiciona eventListeners a objetos no palco.
		private function addListeners():void
		{
			okButon.addEventListener(MouseEvent.CLICK, debugPosicoes);
			
			nextButton.addEventListener(MouseEvent.CLICK, reset);
			
			valendoNota.addEventListener(MouseEvent.CLICK, mostraTelaValendo);
			
			telaMensagens.okBTN.addEventListener(MouseEvent.CLICK, escondeTelaMensagem);
			
			addListenerArrastePecas();
		}
		
		//Abre a tela indicando ao aluno que a atividade valerá nota.
		private function mostraTelaValendo(e:MouseEvent):void 
		{
			telaValendo.visible = true;
			setChildIndex(telaValendo, numChildren - 1);
			telaValendo.okBtn.addEventListener(MouseEvent.CLICK, fazExercicioValer);
			telaValendo.cancelBtn.addEventListener(MouseEvent.CLICK, cancelaValendo);
		}
		
		//Após a tela valendo ser aceita o exercício é reiniciado com uma nova configuração e alguns elementos são escondidos na tela.
		private function fazExercicioValer(e:MouseEvent):void 
		{
			telaValendo.visible = false;
			
			reset();
			
			valendoBoolean = true;
			valendoNota.visible = false;
			nextButton.visible = false;
			
			telaValendo.okBtn.removeEventListener(MouseEvent.CLICK, fazExercicioValer);
			telaValendo.cancelBtn.removeEventListener(MouseEvent.CLICK, cancelaValendo);
		}
		
		//Caso o aluno não queira realizar o exercício valendo nota ele pode optar por cancelar essa operação, apenas fechando a tela.
		private function cancelaValendo(e:MouseEvent):void 
		{
			telaValendo.visible = false;
			telaValendo.okBtn.removeEventListener(MouseEvent.CLICK, fazExercicioValer);
			telaValendo.cancelBtn.removeEventListener(MouseEvent.CLICK, cancelaValendo);
		}
		
		//Adiciona eventListener de arraste nas pecas no palco, para que o aluno possa movimentar as peças.
		private function addListenerArrastePecas():void
		{
			for (var i:int = 3; i < arrayPecas.length; i++) 
			{
				arrayPecas[i].addEventListener(MouseEvent.MOUSE_DOWN, initArrastePecas);
			}
		}
		
		//Retira os eventListeners para movimentação das peças.
		//A função é chamada quando o exercício é finalizado, e as peças não podem ser mexidas.
		private function removeListenerArrastePecas():void
		{
			for (var i:int = 3; i < arrayPecas.length; i++) 
			{
				arrayPecas[i].removeEventListener(MouseEvent.MOUSE_DOWN, initArrastePecas);
			}
		}
		
		//Inicia a lista com o nome das funções que podem ser adicionadas no palco
		//As funções são movieClips na Library.
		private function initListaFuncoes():void
		{
			if (listaFuncoes == null) listaFuncoes = [];
			else listaFuncoes.splice(0);
			
			for (var i:int = 0; i < NUM_TOTAL_FUNCOES; i++) 
			{
				listaFuncoes.push("Funcao" + String(i + 1));
			}
		}
		
		//Sorteio das funções (3) que aparecerão na tela.
		private function sorteiaFuncoes():void
		{
			if (funcoesSorteadas == null) funcoesSorteadas = [];
			else funcoesSorteadas.splice(0);
			
			for (var i:int = 0; i < ORDEM_MATRIX.y; i++) 
			{
				var sort:Number = Math.floor(Math.random() * listaFuncoes.length);
				var Funcao:Class = getDefinitionByName(listaFuncoes[sort]) as Class;
				
				for (var j:int = 0; j < ORDEM_MATRIX.x; j++) 
				{
					funcoesSorteadas.push(new Funcao());
					funcoesSorteadas[funcoesSorteadas.length - 1].gotoAndStop(j + 1);
				}
				
				listaFuncoes.splice(sort, 1);
			}
		}
		
		//Posicionamento das peças no palco de forma aleatória.
		private function posicionaPecas():void
		{
			if (arrayPecas == null) arrayPecas = [];
			else 
			{
				for (var i:int = 0; i < arrayPecas.length; i++) 
				{
					removeChild(arrayPecas[i]);
				}
				arrayPecas.splice(0);
			}
			
			dicionarioPecas = new Dictionary();
			pecasDicionario = new Dictionary();
			
			for (i = 0; i < ORDEM_MATRIX.x; i++) 
			{
				for (var j:int = 0; j < ORDEM_MATRIX.y; j++) 
				{
					//Primeira linha
					if (i == 0)
					{
						var sort:Number = j * 3;
					}
					//Demais linhas
					else
					{
						sort = Math.floor(Math.random() * funcoesSorteadas.length);
					}
					
					arrayPecas.push(funcoesSorteadas[sort]);
					
					addChild(arrayPecas[arrayPecas.length - 1]);
					arrayPecas[arrayPecas.length - 1].x = this["fundo" + String(i + 1) + "_" + String(j + 1)].x;
					arrayPecas[arrayPecas.length - 1].y = this["fundo" + String(i + 1) + "_" + String(j + 1)].y;
					
					dicionarioPecas[arrayPecas[arrayPecas.length - 1]] = this["fundo" + String(i + 1) + "_" + String(j + 1)];
					pecasDicionario[this["fundo" + String(i + 1) + "_" + String(j + 1)]] = arrayPecas[arrayPecas.length - 1];
					
					//arrayPecas[arrayPecas.length - 1].addEventListener(MouseEvent.MOUSE_DOWN, initArrastePecas);
					
					if (i != 0) funcoesSorteadas.splice(sort, 1);
					else if (i == 0 && j == 2) {
						funcoesSorteadas.splice(6, 1);
						funcoesSorteadas.splice(3, 1);
						funcoesSorteadas.splice(0, 1);
					}
				}
			}
		}
		
		//Ao clicar (mouseDown) em uma peça essa função é chamada, configurando alguns parâmetros para arraste da peca.
		private function initArrastePecas(e:MouseEvent):void 
		{
			if (tweenXDraging == null || tweenXDraging.isPlaying == false)
			{
				stage.addEventListener(MouseEvent.MOUSE_UP, checkUpPosition);
				
				dragingMC = e.target as MovieClip;
				setChildIndex(dragingMC, numChildren - 1);
				dragingMC.alpha = 0.8;
				inicialPosition = new Point(dragingMC.x, dragingMC.y);
				dragingMC.startDrag();
			}
		}
		
		//Para o arraste da peça e chama a função que realiza a troca das peças.
		private function checkUpPosition(e:MouseEvent):void 
		{
			stage.removeEventListener(MouseEvent.MOUSE_UP, checkUpPosition);
			dragingMC.stopDrag();
			
			trocaPecasLugar();
			
			dragingMC = null;
		}
		
		//Função que realiza a troca das peças
		//Função comentada pois foi substituída pela função seguinte, mais eficiente.
		private function trocaPecasLugar():void
		{
			dragingMC.alpha = 1;
			
			changePlaces();
			
			//var tempoTween:Number = 0.3;
			
			//if (MovieClip(dicionarioPecas[dragingMC]).hitTestPoint(dragingMC.x, dragingMC.y) || isOutOfBounds(dragingMC) )
			//{
				//tweenXDraging = new Tween(dragingMC, "x", None.easeNone, dragingMC.x, inicialPosition.x, tempoTween, true);
				//tweenYDraging = new Tween(dragingMC, "y", None.easeNone, dragingMC.y, inicialPosition.y, tempoTween, true);
			//}
			//else
			//{
				//for (var i:int = 0; i < ORDEM_MATRIX.x; i++) 
				//{
					//for (var j:int = 0; j < ORDEM_MATRIX.y; j++) 
					//{
						//if (this["fundo" + String(i + 1) + "_" + String(j + 1)].hitTestPoint(dragingMC.x, dragingMC.y))
						//{
							//var fundoDropTarget:MovieClip = this["fundo" + String(i + 1) + "_" + String(j + 1)];
							//dropTargetMC = pecasDicionario[fundoDropTarget];
							//
							//setChildIndex(dropTargetMC, numChildren - 1);
							//setChildIndex(dragingMC, numChildren - 1);
						//}
					//}
				//}
				//
				//tweenXDraging = new Tween(dragingMC, "x", None.easeNone, dragingMC.x, fundoDropTarget.x, tempoTween, true);
				//tweenYDraging = new Tween(dragingMC, "y", None.easeNone, dragingMC.y, fundoDropTarget.y, tempoTween, true);
//
				//tweenXDropTarget = new Tween(dropTargetMC, "x", None.easeNone, dropTargetMC.x, inicialPosition.x, tempoTween, true);
				//tweenYDropTarget = new Tween(dropTargetMC, "y", None.easeNone, dropTargetMC.y, inicialPosition.y, tempoTween, true);
				//
				//pecasDicionario[fundoDropTarget] = dragingMC;
				//pecasDicionario[dicionarioPecas[dragingMC]] = dropTargetMC;
				//
				//dicionarioPecas[dropTargetMC] = dicionarioPecas[dragingMC];
				//dicionarioPecas[dragingMC] = fundoDropTarget;
				//
			//}
		}
		
		//Função que realiza a troca das peças
		private function changePlaces():void
		{
			var xIni:Number = fundo1_1.x;
			var yIni:Number = fundo1_1.y;
			var deltaX:Number = 185;
			var deltaY:Number = 130;

			var indiceX:int = Math.round(((dragingMC.x - xIni) / deltaX)) + 1;
			var indiceY:int = Math.round(((dragingMC.y - yIni) / deltaY)) + 1;
			
			var tempoTween:Number = 0.3;
			
			if (indiceX > 0 && indiceX <= ORDEM_MATRIX.x && indiceY > 1 && indiceY <= ORDEM_MATRIX.y && !MovieClip(dicionarioPecas[dragingMC]).hitTestPoint(dragingMC.x, dragingMC.y))
			{
				var fundoDropTarget:MovieClip = this["fundo" + String(indiceY) + "_" + String(indiceX)];
				dropTargetMC = pecasDicionario[fundoDropTarget];
				
				setChildIndex(dropTargetMC, numChildren - 1);
				setChildIndex(dragingMC, numChildren - 1);
				
				tweenXDraging = new Tween(dragingMC, "x", None.easeNone, dragingMC.x, fundoDropTarget.x, tempoTween, true);
				tweenYDraging = new Tween(dragingMC, "y", None.easeNone, dragingMC.y, fundoDropTarget.y, tempoTween, true);

				tweenXDropTarget = new Tween(dropTargetMC, "x", None.easeNone, dropTargetMC.x, inicialPosition.x, tempoTween, true);
				tweenYDropTarget = new Tween(dropTargetMC, "y", None.easeNone, dropTargetMC.y, inicialPosition.y, tempoTween, true);
				
				pecasDicionario[fundoDropTarget] = dragingMC;
				pecasDicionario[dicionarioPecas[dragingMC]] = dropTargetMC;
				
				dicionarioPecas[dropTargetMC] = dicionarioPecas[dragingMC];
				dicionarioPecas[dragingMC] = fundoDropTarget;
			}
			else
			{
				tweenXDraging = new Tween(dragingMC, "x", None.easeNone, dragingMC.x, inicialPosition.x, tempoTween, true);
				tweenYDraging = new Tween(dragingMC, "y", None.easeNone, dragingMC.y, inicialPosition.y, tempoTween, true);
			}
		}
		
		//Ao finalizar o exercício e clicar em OK essa função é chamada.
		//Ela verifica o posicionamento das peças, aplicando filtro de glow nas que estão erradas.
		//Adiciona também o listener para mostrar as posições corretas.
		//Também calcula a pontuação de acordo com o número de peças corretamente posicionadas, caso esteja valendo a pontuação é salva no LMS.
		private function debugPosicoes(e:MouseEvent):void
		{
			removeListenerArrastePecas();
			
			var tipo1:String = String(pecasDicionario[fundo1_1]);
			var tipo2:String = String(pecasDicionario[fundo1_2]);
			var tipo3:String = String(pecasDicionario[fundo1_3]);
			
			for (var j:int = 1; j <= ORDEM_MATRIX.y; j++) 
			{
				var tipoAtual:String;
				if (j == 1) tipoAtual = tipo1;
				else if (j == 2) tipoAtual = tipo2;
				else tipoAtual = tipo3;
				
				for (var i:int = 1; i <= ORDEM_MATRIX.x; i++) 
				{
					if (i == 1)
					{
						pecasDicionario[this["fundo" + String(i) + "_" + String(j)]].filters = [];
					}
					else
					{
						if (String(pecasDicionario[this["fundo" + String(i) + "_" + String(j)]]) == tipoAtual)
						{
							if (pecasDicionario[this["fundo" + String(i) + "_" + String(j)]].currentFrame != i) pecasDicionario[this["fundo" + String(i) + "_" + String(j)]].filters = [filtroErrado];
							else {
								if (calculaPontuacao) {
									pontuacao += 100 / 6;
								}
								pecasDicionario[this["fundo" + String(i) + "_" + String(j)]].filters = [];
							}
						}
						else
						{
							pecasDicionario[this["fundo" + String(i) + "_" + String(j)]].filters = [filtroErrado];
						}
					}
				}
			}
			
			if (valendoBoolean) {
				lastTimes += 1;
				lastScore += pontuacao / maxTimes;
				if (lastTimes == maxTimes) {
					completed = true;
					valendoBoolean = false;
				}
				
				save2LMS();
				abreTelaMensagem(INICIO_MSG + String(int(pontuacao)) + MSG_COMPLETED_EXTENDED);
			} else {
				
				if(calculaPontuacao) abreTelaMensagem(INICIO_MSG + String(int(pontuacao)) + MSG_FINISHED);
			}
			if (calculaPontuacao) calculaPontuacao = false;
			
			adicionaListenerGlowsCorretos();
			
			nextButton.visible = true;
		}
		
		//Adiciona eventListener nas peças no palco para mostrar as posições corretas das peças.
		private function adicionaListenerGlowsCorretos():void
		{
			for (var i:int = 0; i < arrayPecas.length; i++) 
			{
				arrayPecas[i].addEventListener(MouseEvent.MOUSE_DOWN, coloreGrupoFuncoes);
			}
		}
		
		//Remove os eventListeners que mostram as posições corretas das peças.
		private function removeListenerGlowsCorretos():void
		{
			for (var i:int = 0; i < arrayPecas.length; i++) 
			{
				arrayPecas[i].removeEventListener(MouseEvent.MOUSE_DOWN, coloreGrupoFuncoes);
			}
		}
		
		//Função que colore as 3 peças de um mesmo grupo, indicando também qual a função, a derivada e a segunda derivada da função.
		private function coloreGrupoFuncoes(e:MouseEvent):void 
		{
			removeGlowsErrados();
			stage.addEventListener(MouseEvent.MOUSE_UP, coloreErrados);
			
			var tipoGrupo:String = String(e.target);
			
			for (var i:int = 0; i < arrayPecas.length; i++) 
			{
				if (String(arrayPecas[i]) == tipoGrupo) 
				{
					arrayPecas[i].filters = [filtroGrupo];
					if (arrayPecas[i].currentFrame == 1) {
						funcao.x = arrayPecas[i].x + arrayPecas[i].width / 2;
						funcao.y = arrayPecas[i].y - arrayPecas[i].height / 2;
						funcao.visible = true;
						setChildIndex(funcao, numChildren - 1);
					} else if (arrayPecas[i].currentFrame == 2) {
						derivadaPrimeira.x = arrayPecas[i].x + arrayPecas[i].width / 2;
						derivadaPrimeira.y = arrayPecas[i].y - arrayPecas[i].height / 2;
						derivadaPrimeira.visible = true;
						setChildIndex(derivadaPrimeira, numChildren - 1);
					} else {
						derivadaSegunda.x = arrayPecas[i].x + arrayPecas[i].width / 2;
						derivadaSegunda.y = arrayPecas[i].y - arrayPecas[i].height / 2;
						derivadaSegunda.visible = true;
						setChildIndex(derivadaSegunda, numChildren - 1);
					}
				}
			}
		}
		
		//Remove os filtros das peças no palco.
		private function removeGlowsErrados():void
		{
			for (var i:int = 0; i < arrayPecas.length; i++) 
			{
				arrayPecas[i].filters = [];
			}
		}
		
		//Após mostrar a posição correta das peças essa função adiciona filtros de glow nas peças que estão na posição errada.
		private function coloreErrados(e:MouseEvent):void 
		{
			stage.removeEventListener(MouseEvent.MOUSE_UP, coloreErrados);
			removeListenerGlowsCorretos();
			funcao.visible = false;
			derivadaPrimeira.visible = false;
			derivadaSegunda.visible = false;
			debugPosicoes(null);
		}
		
		//Função que retorna se a peça está fora dos limites do "tabuleiro".
		//Função não é mais usada pois uma nova forma de reposicionar as peças está sendo utilizado.
		private function isOutOfBounds(mc:MovieClip):Boolean
		{
			if (mc.x < 42.5 || mc.x > 640 - 42.5 || mc.y < 35 || mc.y > 35 + 389.95) return true;
			else return false;
		}
		
		
		
		//-------------------------------------------------------------------------------------------------------------------------------------------------------------
		
		/* SCORM */
		
		private const PING_INTERVAL:Number = 5 * 60 * 1000; // 5 minutos
		
		//SCORM VARIABLES
		private var completed:Boolean;
		private var scorm:SCORM;
		private var scormTimeTry:String;
		private var connected:Boolean;
		private var score:int;
		private var pingTimer:Timer;
		private var lastTimes:int = 0;//quantas vezes ele ja fez
		private var lastScore:int = 0;//pontuação anterior
		private var maxTimes:int = 1;
		private var respondido:Boolean;
		private var tweenMenu:Tween;
		
		
		/**
		 * @private
		 * Inicia a conexão com o LMS.
		 */
		private function initLMSConnection () : void
		{
			
			completed = false;
			connected = false;
			
			scorm = new SCORM();

			connected = scorm.connect();
			
			if (connected) {
 
				// Verifica se a AI já foi concluída.
				var status:String = scorm.get("cmi.completion_status");	
				
				switch(status)
				{
					// Primeiro acesso à AI// Continuando a AI...
					case "not attempted":
					case "unknown":
					default:
						completed = false;
						scormTimeTry = "times=0,points=0";
						score = 0;
						break;
					
					case "incomplete":
						completed = false;
						scormTimeTry = scorm.get("cmi.location");
						score = 0;
						break;
						
					// A AI já foi completada.
					case "completed"://Apartir desse momento os pontos nao serão mais acumulados
						completed = true;
						scormTimeTry = scorm.get("cmi.location");//Deve contar a quantidade de funções que ele fez e tambem média que ele tinha
						score = 0;
						//setMessage("ATENÇÃO: esta Atividade Interativa já foi completada. Você pode refazê-la quantas vezes quiser, mas não valerá nota.");
						break;
				}
				//Tratamento do scormTimeTry--------------------------------------------------------------------
				if (!completed)//Somente se a atividade nao estiver completa
				{
					var lista:Array = scormTimeTry.split(",");
					for(var i = 0; i < lista.length; i++)
					{
						if(i == 0)
						{
							lastTimes = int(lista[i].substr(lista[i].search("=") + 1));
							
						}else if(i == 1)
						{
							lastScore = int(lista[i].substr(lista[i].search("=") + 1));
							
						}
					}
				}
				
				//----------------------------------------------------------------------------------------------
				var success:Boolean = scorm.set("cmi.score.min", "0");
				if (success) success = scorm.set("cmi.score.max", "100");
				
				if (success)
				{
					scorm.save();
					if (pingTimer == null) {
						pingTimer = new Timer(PING_INTERVAL);
						pingTimer.start();
						pingTimer.addEventListener(TimerEvent.TIMER, pingLMS);
					}
				}
				else
				{
					//trace("Falha ao enviar dados para o LMS.");
					connected = false;
				}
			}
			else
			{
				//setMessage("Esta Atividade Interativa não está conectada a um LMS: seu aproveitamento nela NÃO será salvo.");
			}
			//reset();
		}
		
		/**
		 * @private
		 * Salva cmi.score.raw, cmi.location e cmi.completion_status no LMS
		 */ 
		private function save2LMS ()
		{
			if (connected)
			{
				// Salva no LMS a nota do aluno.
				lastScore = Math.max(0, Math.min(lastScore, 100));
				var success:Boolean = scorm.set("cmi.score.raw", (lastScore).toString());

				// Notifica o LMS que esta atividade foi concluída.
				success = scorm.set("cmi.completion_status", (completed ? "completed" : "incomplete"));

				// Salva no LMS o exercício que deve ser exibido quando a AI for acessada novamente.
				scormTimeTry = "times=" + lastTimes + ",points=" + lastScore;
				success = scorm.set("cmi.location", scormTimeTry);

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
			scorm.get("cmi.completion_status");
		}
		//-------------------------------------------------------------------------------------------------------------------------------------------------------------
	}
}