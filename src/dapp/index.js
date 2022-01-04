import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';

(async () => {
  let result = null;

  function buyInsurance(airline, flight, timestamp) {
    console.log('buy insurance');

    contract
      .buyInsurance(airline, flight, timestamp)
      .then((response) => {
        alert('Successfully bought insurance');
      })
      .catch((error) => {
        if (error.message.indexOf('Passenger has insurance') !== -1) {
          alert('You already bought insurance for this flight: ' + flight);
        } else {
          alert('System error, cannot proceed at this time: ', error.message);
        }
      });
  }

  function submitToOracles(airline, flight, timestamp) {
    contract
      .getFlightStatus(airline, flight, timestamp)
      .then((results) => {
        // console.log(results);

        const { events } = results;
        // console.log(events);

        const values = events.OracleRequest.returnValues;

        console.log(values);

        contract
          .getFlightStatusCode(airline, flight, timestamp)
          .then((statusCode) => {
            console.log('statusCode: ', statusCode);

            DOM.elid('status-' + flight).textContent =
              'Status: ' + contract.statusCodeToText(statusCode);
          });
      })
      .catch((err) => alert('Error encountered. Please try again later.'));
  }

  let contract = new Contract('localhost', () => {
    // Read transaction
    contract.isOperational((error, result) => {
      console.log(error, result);
      display('Operational Status', 'Check if contract is operational', [
        { label: 'Operational Status', error: error, value: result },
      ]);
    });

    // User-submitted transaction
    DOM.elid('submit-oracle').addEventListener('click', () => {
      let flight = DOM.elid('flight-number').value;
      // Write transaction
      contract.fetchFlightStatus(flight, (error, result) => {
        console.log(result);
        display('Oracles', 'Trigger oracles', [
          {
            label: 'Fetch Flight Status',
            error: error,
            value: result.flight + ' ' + result.timestamp,
          },
        ]);
      });
    });

    DOM.elid('flights').addEventListener('click', async () => {
      console.log('Get List');

      fetch('http://localhost:3000/flights')
        .then((response) => response.json())
        .then((data) => {
          console.log(data);

          let displayDiv = DOM.elid('flightsList');
          let section = DOM.div({ className: 'container-md' });

          data.map((item) => {
            let row = section.appendChild(DOM.div({ className: 'row top-20' }));
            row.appendChild(
              DOM.div({ className: 'col-sm-4 field' }, item.flight)
            );
            row.appendChild(
              DOM.button(
                {
                  className: 'btn btn-primary ml-3',
                  id: 'buy-' + item.flight,
                  onclick: () =>
                    buyInsurance(item.airline, item.flight, item.timestamp),
                },
                'Buy'
              )
            );
            row.appendChild(
              DOM.button(
                {
                  className: 'btn btn-primary ml-3',
                  id: 'submit-' + item.flight,
                  onclick: () =>
                    submitToOracles(item.airline, item.flight, item.timestamp),
                },
                'Submit to Oracles'
              )
            );

            row.appendChild(
              DOM.span(
                { className: 'font-weight-bold', id: 'status-' + item.flight },
                'Status: Unknown'
              )
            );

            section.appendChild(row);
          });

          displayDiv.append(section);
        });
    });
  });
})();

function display(title, description, results) {
  let displayDiv = DOM.elid('display-wrapper');
  let section = DOM.section();
  section.appendChild(DOM.h2(title));
  section.appendChild(DOM.h5(description));
  results.map((result) => {
    let row = section.appendChild(DOM.div({ className: 'row' }));
    row.appendChild(DOM.div({ className: 'col-sm-4 field' }, result.label));
    row.appendChild(
      DOM.div(
        { className: 'col-sm-8 field-value' },
        result.error ? String(result.error) : String(result.value)
      )
    );
    section.appendChild(row);
  });
  displayDiv.append(section);
}
