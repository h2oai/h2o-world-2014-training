package storm.starter;

import backtype.storm.Config;
import backtype.storm.spout.SpoutOutputCollector;
import backtype.storm.task.TopologyContext;
import backtype.storm.topology.OutputFieldsDeclarer;
import backtype.storm.topology.base.BaseRichSpout;
import backtype.storm.tuple.Fields;
import backtype.storm.tuple.Values;
import backtype.storm.utils.Utils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;


public class TestH2ODataSpout extends BaseRichSpout {
  public static Logger LOG = LoggerFactory.getLogger(TestH2ODataSpout.class);
  boolean _isDistributed;
  SpoutOutputCollector _collector;
  AtomicInteger _cnt = new AtomicInteger(0);


  public TestH2ODataSpout() {
    this(true);
  }

  public TestH2ODataSpout(boolean isDistributed) {
    _isDistributed = isDistributed;
  }

  public void open(Map conf, TopologyContext context, SpoutOutputCollector collector) {
    _collector = collector;
  }

  public void close() {

  }

  public void nextTuple() {
    Utils.sleep(1000);
    final String[][] data = new String[][] {
      {"1","dog","1","Brown","0","1","1","1","2","1","0","6","0.58597831428051","0.511964808916673","0.568346169544384","0.72301404341124","0.914444969035685"},
      {"2","dog","1","Spotted","1","2","1","1","5","1","1","20","0.0193322147242725","0.218708470463753","0.997939549386501","0.787821364589036","0.564598099794239"},
      {"3","dog","1","Grey","1","1","0","0","2","0","0","18","0.517114334739745","0.482429623603821","0.0349245818797499","0.140521091874689","0.760355275822803"},
      {"4","dog","1","Brown","0","1","1","1","2","1","1","5","0.6041005034931","0.265517421998084","0.607328588142991","0.0746244699694216","0.382541742175817"},
      {"5","cat","1","White","1","9","1","1","5","0","0","4","0.902391067240387","0.431803715182468","0.0665075136348605","0.201563291018829","0.118178829085082"},
      {"6","dog","1","Brown","1","3","1","1","2","0","0","4","0.792452512308955","0.324701636796817","0.35222681122832","0.701774889603257","0.145541392965242"},
      {"7","dog","1","Brown","1","3","1","1","2","1","0","10","0.193223899696022","0.37546653021127","0.546671659685671","0.54458834649995","0.733291923999786"},
      {"8","dog","1","Brown","1","1","0","1","5","1","0","18","0.376205187523738","0.772026713937521","0.331484596244991","0.711952167097479","0.0442128055728972"},
      {"9","cat","1","Grey","1","6","1","1","5","0","1","19","0.498364995233715","0.835489227203652","0.772988627199084","0.639661098830402","0.465114348800853"},
      {"10","dog","1","Spotted","1","10","1","1","2","1","1","11","0.577296334318817","0.422361127333716","0.266010194085538","0.811606602510437","0.488387528108433"}
    };
    if (_cnt.get() == data.length) {_cnt.set(0);}
    final String[] word = data[_cnt.get()];
    _cnt.getAndIncrement();
    _collector.emit(new Values(word));
  }

  public void ack(Object msgId) {

  }

  public void fail(Object msgId) {

  }

  public void declareOutputFields(OutputFieldsDeclarer declarer) {
    String[] fields = new String[17];
    fields[0] = "ID";
    fields[1] = "Label";
    fields[2] = "Has4Legs";
    fields[3] = "CoatColor";
    fields[4] = "HasLongHair";
    fields[5] = "TailLength";
    fields[6] = "EnjoysPlay";
    fields[7] = "StairsOutWindow";
    fields[8] = "HoursSpentNapping";
    fields[9] = "RespondsToCommands";
    fields[10] = "EasilyFrightened";
    fields[11]= "Age";
    fields[12]= "C11";
    fields[13]= "C12";
    fields[14]= "C13";
    fields[15]= "C14";
    fields[16]= "C15";
    declarer.declare(new Fields(fields));
  }

  @Override
  public Map<String, Object> getComponentConfiguration() {
    if(!_isDistributed) {
      Map<String, Object> ret = new HashMap<String, Object>();
      ret.put(Config.TOPOLOGY_MAX_TASK_PARALLELISM, 1);
      return ret;
    } else {
      return null;
    }
  }
}