import { useForm } from 'react-hook-form';

type Props = {
  onPredict: (data: any) => void;
};

type FormValues = {
  region: string;
  date: string;
  seaLevel: number;
  erosionRate: number;
  precipitation: number;
};

export const PredictionForm: React.FC<Props> = ({ onPredict }) => {
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<FormValues>();

  const onSubmit = (data: FormValues) => {
    onPredict(data);
    reset();
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="row g-3">
      <div className="col-md-4">
        <input
          className={`form-control ${errors.region ? 'is-invalid' : ''}`}
          placeholder="Region"
          {...register('region', { required: 'Region is required' })}
        />
        {errors.region && <div className="invalid-feedback">{errors.region.message}</div>}
      </div>
      <div className="col-md-4">
        <input
          type="date"
          className={`form-control ${errors.date ? 'is-invalid' : ''}`}
          placeholder="Date"
          {...register('date', { required: 'Date is required' })}
        />
        {errors.date && <div className="invalid-feedback">{errors.date.message}</div>}
      </div>
      <div className="col-md-4">
        <input
          type="number"
          step="any"
          className={`form-control ${errors.seaLevel ? 'is-invalid' : ''}`}
          placeholder="Sea Level"
          {...register('seaLevel', {
            required: 'Sea Level is required',
            valueAsNumber: true,
          })}
        />
        {errors.seaLevel && <div className="invalid-feedback">{errors.seaLevel.message}</div>}
      </div>
      <div className="col-md-4">
        <input
          type="number"
          step="any"
          className={`form-control ${errors.erosionRate ? 'is-invalid' : ''}`}
          placeholder="Erosion Rate"
          {...register('erosionRate', {
            required: 'Erosion Rate is required',
            valueAsNumber: true,
          })}
        />
        {errors.erosionRate && <div className="invalid-feedback">{errors.erosionRate.message}</div>}
      </div>
      <div className="col-md-4">
        <input
          type="number"
          step="any"
          className={`form-control ${errors.precipitation ? 'is-invalid' : ''}`}
          placeholder="Precipitation"
          {...register('precipitation', {
            required: 'Precipitation is required',
            valueAsNumber: true,
          })}
        />
        {errors.precipitation && <div className="invalid-feedback">{errors.precipitation.message}</div>}
      </div>
      <div className="col-md-4 d-flex align-items-end">
        <button type="submit" className="btn btn-primary w-100">
          Predict
        </button>
      </div>
    </form>
  );
};
