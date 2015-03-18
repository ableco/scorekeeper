var TopThree = React.createClass({
  render: function() {
    var scores = this.props.data.map(function(score, index) {
      return (
        // `key` is a React-specific concept and is not mandatory for the
        // purpose of this tutorial. if you're curious, see more here:
        // http://facebook.github.io/react/docs/multiple-components.html#dynamic-children
        <Score name={score.name} score={score.score} key={index} />
      );
    });
    return (
      <div className="TopThree">
        {scores}
      </div>
    );
  }
});

var Score = React.createClass({
  render: function() {
    return (
      <div className="scorefff">
        {this.props.name} {this.props.score}
      </div>
    );
  }
});

var Scoreboard = React.createClass({
  loadScoresFromServer: function() {
    $.ajax({
      url: this.props.url,
      dataType: 'json',
      crossDomain: true,
      success: function(data) {
        this.setState({data: data});
      }.bind(this),
      error: function(xhr, status, err) {
        console.error(this.props.url, status, err.toString());
      }.bind(this)
    });
  },
  getInitialState: function() {
    return {data: []};
  },
  componentDidMount: function() {
    this.loadScoresFromServer();
    setInterval(this.loadScoresFromServer, this.props.pollInterval);
  },
  render: function() {
    return (
      <div className="scoreboard">
        <h1>Scores</h1>
        <TopThree data={this.state.data} />
      </div>
    );
  }
});

React.render(
  <Scoreboard url="http://disrupto-scorekeeper.herokuapp.com/scores" pollInterval={5000} />,
  document.getElementById('content')
);